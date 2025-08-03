import argv
import external_things.{exit}
import gleam/io
import gleam/result
import parser.{parse}
import printer.{print}
import simplifile.{type FileError, describe_error}
import tokenizer.{tokenize}
import ast_printer

pub fn main() -> Nil {
  case argv.load().arguments {
    ["tokenize", filename] -> {
      case handle_tokenize(filename) {
        Ok(_) -> Nil
        Error(err) -> {
          io.println_error(describe_error(err))
          exit(1)
        }
      }
    }
    ["parse", filename] -> {
      case handle_parse(filename) {
        Ok(_) -> Nil
        Error(err) -> {
          err |> describe_error |> io.println_error
          exit(1)
        }
      }
    }
    _ -> {
      io.println_error("Usage: ./your_program.sh tokenize <filename>")
      exit(1)
    }
  }
}

pub fn handle_tokenize(
  filename: String,
) -> Result(Nil, FileError) {
  use contents <- result.try(simplifile.read(filename))
  let result = tokenize(contents)

  result |> print

  case result.errors {
    [] -> Ok(Nil)
    _ -> {
      exit(65)
      Ok(Nil)  // unreachable but satisfies Gleam's type system
    }
  }
}


pub fn handle_parse(filename: String) -> Result(Nil, FileError) {
  use contents <- result.try(simplifile.read(filename))
  tokenizer.tokenize(contents).tokens 
  |> parse 
  |> ast_printer.print
  Ok(Nil)
}
