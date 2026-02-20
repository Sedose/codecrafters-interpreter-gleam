import argv
import ast_printer
import external_things.{exit}
import gleam/io
import parse_error_printer.{format_error}
import parser.{parse}
import simplifile.{describe_error}
import tokenization_printer.{print, print_errors}
import tokenizer.{tokenize}

const exit_code_success = 0

const exit_code_general_error = 1

const exit_code_tokenization_error = 65

const usage_message = "Usage: ./your_program.sh tokenize|parse <filename>"

pub fn main() -> Nil {
  let exit_code = case argv.load().arguments {
    ["tokenize", filename] -> execute_with_file(filename, process_tokenize)
    ["parse", filename] -> execute_with_file(filename, process_parse)
    _ -> {
      io.println_error(usage_message)
      exit_code_general_error
    }
  }

  exit(exit_code)
}

fn execute_with_file(filename: String, process: fn(String) -> Int) -> Int {
  case simplifile.read(filename) {
    Ok(contents) -> process(contents)
    Error(err) -> {
      err
      |> describe_error
      |> io.println_error
      exit_code_general_error
    }
  }
}

fn process_tokenize(contents: String) -> Int {
  let tokenization_result = tokenize(contents)
  tokenization_result |> print

  case tokenization_result.errors {
    [] -> exit_code_success
    _ -> exit_code_tokenization_error
  }
}

fn process_parse(contents: String) -> Int {
  let tokenization_result = tokenize(contents)

  case tokenization_result.errors {
    [] ->
      case parse(tokenization_result.tokens) {
        Ok(expression) -> {
          expression |> ast_printer.print
          exit_code_success
        }
        Error(error) -> {
          error |> format_error |> io.println_error
          exit_code_tokenization_error
        }
      }
    errors -> {
      errors |> print_errors
      exit_code_tokenization_error
    }
  }
}
