import argv
import ast_printer
import data_def.{type Expr, type LiteralValue, TokenizationResult}
import evaluator
import external_things.{exit}
import gleam/io
import parse_error_printer.{format_error}
import parser.{parse}
import simplifile.{describe_error}
import tokenization_printer.{print, print_errors}
import tokenizer.{tokenize}

const exit_code_success = 0

const exit_code_general_error = 1

const exit_code_language_error = 65

const exit_code_runtime_error = 70

const usage_message = "Usage: ./your_program.sh tokenize|parse|evaluate <filename>"

pub fn main() -> Nil {
  let exit_code = case argv.load().arguments {
    ["tokenize", filename] -> execute_with_file(filename, process_tokenize)
    ["parse", filename] -> execute_with_file(filename, process_parse)
    ["evaluate", filename] -> execute_with_file(filename, process_evaluate)
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
    _ -> exit_code_language_error
  }
}

fn process_parse(contents: String) -> Int {
  case contents |> tokenize_and_parse {
    Ok(expression) -> {
      expression |> ast_printer.print
      exit_code_success
    }
    Error(exit_code) -> exit_code
  }
}

fn process_evaluate(contents: String) -> Int {
  case contents |> tokenize_and_parse {
    Ok(expression) -> expression |> evaluator.evaluate |> resolve_evaluation
    Error(exit_code) -> exit_code
  }
}

fn tokenize_and_parse(contents: String) -> Result(Expr, Int) {
  case tokenize(contents) {
    TokenizationResult(tokens: tokens, errors: []) ->
      case parse(tokens) {
        Ok(expression) -> Ok(expression)
        Error(error) -> {
          error |> format_error |> io.println_error
          Error(exit_code_language_error)
        }
      }
    TokenizationResult(tokens: _, errors: errors) -> {
      errors |> print_errors
      Error(exit_code_language_error)
    }
  }
}

fn resolve_evaluation(evaluation_result: Result(LiteralValue, String)) -> Int {
  case evaluation_result {
    Ok(value) -> {
      value |> evaluator.format |> io.println
      exit_code_success
    }
    Error(message) -> {
      message |> io.println_error
      exit_code_runtime_error
    }
  }
}
