import argv
import command_result
import command_runner
import data_def.{exit_code_general_error}
import external_things.{exit}
import gleam/io

const usage_message = "Usage: ./your_program.sh tokenize|parse|evaluate|run <filename>"

type Command {
  Tokenize(String)
  Parse(String)
  Evaluate(String)
  Run(String)
}

pub fn main() -> Nil {
  argv.load().arguments
  |> run
  |> exit
}

fn run(arguments: List(String)) -> Int {
  case parse_command(arguments) {
    Ok(command) -> dispatch(command)
    Error(Nil) -> usage_error()
  }
}

fn parse_command(arguments: List(String)) -> Result(Command, Nil) {
  case arguments {
    ["tokenize", filename] -> Ok(Tokenize(filename))
    ["parse", filename] -> Ok(Parse(filename))
    ["evaluate", filename] -> Ok(Evaluate(filename))
    ["run", filename] -> Ok(Run(filename))
    _ -> Error(Nil)
  }
}

fn dispatch(command: Command) -> Int {
  case command {
    Tokenize(filename) ->
      run_file_command(
        filename,
        command_runner.process_tokenize,
        command_result.resolve_tokenize_result,
      )
    Parse(filename) ->
      run_file_command(
        filename,
        command_runner.process_parse,
        command_result.resolve_parse_result,
      )
    Evaluate(filename) ->
      run_file_command(
        filename,
        command_runner.process_evaluate,
        command_result.resolve_evaluation_result,
      )
    Run(filename) ->
      run_file_command(
        filename,
        command_runner.process_run,
        command_result.resolve_run_result,
      )
  }
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
  io.println_error(usage_message)
  exit_code_general_error
}
