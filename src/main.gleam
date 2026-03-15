import argv
import command_result
import command_runner
import data_def.{exit_code_general_error}
import external_things.{exit}
import gleam/io

const usage_message = "Usage: ./your_program.sh tokenize|parse|evaluate|run <filename>"

pub fn main() -> Nil {
  argv.load().arguments
  |> dispatch
  |> exit
}

pub fn dispatch(arguments: List(String)) -> Int {
  case arguments {
    ["tokenize", filename] ->
      execute_command(
        filename,
        command_runner.process_tokenize,
        command_result.resolve_tokenize_result,
      )
    ["parse", filename] ->
      execute_command(
        filename,
        command_runner.process_parse,
        command_result.resolve_parse_result,
      )
    ["evaluate", filename] ->
      execute_command(
        filename,
        command_runner.process_evaluate,
        command_result.resolve_evaluation_result,
      )
    ["run", filename] ->
      execute_command(
        filename,
        command_runner.process_run,
        command_result.resolve_run_result,
      )
    _ -> {
      io.println_error(usage_message)
      exit_code_general_error
    }
  }
}

fn execute_command(
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
