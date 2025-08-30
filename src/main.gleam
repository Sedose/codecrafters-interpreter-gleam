import argv
import ast_printer
import external_things.{exit}
import gleam/io
import parser.{parse}
import printer.{print}
import simplifile.{describe_error}
import tokenizer.{tokenize}

const exit_code_success = 0

const exit_code_general_error = 1

const exit_code_tokenization_error = 65

const usage_message = "Usage: ./your_program.sh tokenize <filename>"

pub fn main() -> Nil {
  let exit_code = case argv.load().arguments {
    ["tokenize", filename] -> handle_tokenize(filename)
    ["parse", filename] -> handle_parse(filename)
    _ -> {
      io.println_error(usage_message)
      exit_code_general_error
    }
  }

  exit(exit_code)
}

pub fn handle_tokenize(filename: String) -> Int {
  case simplifile.read(filename) {
    Ok(contents) -> {
      let tokenization_result = tokenize(contents)
      tokenization_result |> print

      case tokenization_result.errors {
        [] -> exit_code_success
        _ -> exit_code_tokenization_error
      }
    }
    Error(err) -> {
      err
      |> describe_error
      |> io.println_error
      exit_code_general_error
    }
  }
}

pub fn handle_parse(filename: String) -> Int {
  case simplifile.read(filename) {
    Ok(contents) -> {
      contents
      |> tokenizer.tokenize
      |> fn(result) { result.tokens }
      |> parse
      |> ast_printer.print

      exit_code_success
    }
    Error(err) -> {
      err
      |> describe_error
      |> io.println_error
      exit_code_general_error
    }
  }
}
