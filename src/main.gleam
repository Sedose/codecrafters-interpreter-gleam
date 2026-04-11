import argv
import command_result
import command_runner
import data_def.{exit_code_general_error}
import external_things.{exit}
import gleam/io
import gleam/result

type CommandSpec {
  CommandSpec(name: String, run: fn(String) -> Int)
}

type ParsedCommand {
  ParsedCommand(command: CommandSpec, filename: String)
}

pub fn main() -> Nil {
  argv.load().arguments
  |> run
  |> exit
}

fn run(arguments: List(String)) -> Int {
  case parse_command(arguments) {
    Ok(ParsedCommand(command:, filename:)) -> dispatch(command, filename)
    Error(Nil) -> usage_error()
  }
}

fn parse_command(arguments: List(String)) -> Result(ParsedCommand, Nil) {
  case arguments {
    [command_name, filename] ->
      command_specs()
      |> find_command(command_name)
      |> result.map(fn(command) {
        ParsedCommand(command: command, filename: filename)
      })
    _ -> Error(Nil)
  }
}

fn dispatch(command: CommandSpec, filename: String) -> Int {
  let CommandSpec(_, run_command) = command
  run_command(filename)
}

fn command_specs() -> List(CommandSpec) {
  [
    CommandSpec("tokenize", tokenize_command),
    CommandSpec("parse", parse_command_runner),
    CommandSpec("evaluate", evaluate_command),
    CommandSpec("run", run_command),
  ]
}

fn find_command(
  commands: List(CommandSpec),
  command_name: String,
) -> Result(CommandSpec, Nil) {
  case commands {
    [] -> Error(Nil)
    [command, ..rest] ->
      case command {
        CommandSpec(name, _) if name == command_name -> Ok(command)
        _ -> find_command(rest, command_name)
      }
  }
}

fn command_names(commands: List(CommandSpec)) -> List(String) {
  case commands {
    [] -> []
    [CommandSpec(name, _), ..rest] -> [name, ..command_names(rest)]
  }
}

fn usage_message() -> String {
  "Usage: ./your_program.sh "
  <> join_with_pipe(command_specs() |> command_names)
  <> " <filename>"
}

fn join_with_pipe(parts: List(String)) -> String {
  case parts {
    [] -> ""
    [part] -> part
    [part, ..rest] -> part <> "|" <> join_with_pipe(rest)
  }
}

fn tokenize_command(filename: String) -> Int {
  run_file_command(
    filename,
    command_runner.process_tokenize,
    command_result.resolve_tokenize_result,
  )
}

fn parse_command_runner(filename: String) -> Int {
  run_file_command(
    filename,
    command_runner.process_parse,
    command_result.resolve_parse_result,
  )
}

fn evaluate_command(filename: String) -> Int {
  run_file_command(
    filename,
    command_runner.process_evaluate,
    command_result.resolve_evaluation_result,
  )
}

fn run_command(filename: String) -> Int {
  run_file_command(
    filename,
    command_runner.process_run,
    command_result.resolve_run_result,
  )
}

fn run_file_command(
  filename: String,
  process: fn(String) -> a,
  resolve: fn(a) -> Int,
) -> Int {
  command_runner.execute_with_file(filename, fn(contents) {
    contents
    |> process
    |> resolve
  })
}

fn usage_error() -> Int {
  io.println_error(usage_message())
  exit_code_general_error
}
