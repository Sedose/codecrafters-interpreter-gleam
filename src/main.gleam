import argv
import external_things.{exit}
import gleam/io
import gleam/result
import parser.{parse}
import printer.{print}
import simplifile.{type FileError, describe_error}
import tokenizer.{tokenize}
import ast_printer

const exit_code_general_error = 1
const exit_code_tokenization_error = 65
const usage_message = "Usage: ./your_program.sh tokenize <filename>"

pub fn main() -> Nil {
  case argv.load().arguments {
    ["tokenize", filename] -> filename |> handle_tokenize |> handle_command_result
    ["parse", filename] -> filename |> handle_parse |> handle_command_result
    _ -> {
      io.println_error(usage_message)
      exit(exit_code_general_error)
    }
  }
}

fn handle_command_result(result: Result(Nil, FileError)) -> Nil {
  case result {
    Ok(_) -> Nil
    Error(err) -> {
      err
      |> describe_error
      |> io.println_error
      exit(exit_code_general_error)
    }
  }
}

pub fn handle_tokenize(filename: String) -> Result(Nil, FileError) {
  use contents <- result.try(simplifile.read(filename))
  let tokenization_result = tokenize(contents)
  tokenization_result |> print
  
  case tokenization_result.errors {
    [] -> Ok(Nil)
    _ -> {
      exit(exit_code_tokenization_error)
      // Unreachable code, but required to satisfy Gleam's type system
      // since exit/1 is marked as returning Nil rather than Never
      Ok(Nil)
    }
  }
}

pub fn handle_parse(filename: String) -> Result(Nil, FileError) {
  use contents <- result.try(simplifile.read(filename))
  
  contents
  |> tokenizer.tokenize
  |> fn(result) { result.tokens }
  |> parse
  |> ast_printer.print
  
  Ok(Nil)
}
