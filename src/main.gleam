import argv
import external_things.{exit}
import gleam/io
import gleam/result
import printer.{print}
import simplifile.{type FileError, describe_error}
import tokenizer.{tokenize}

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
    _ -> {
      io.println_error("Usage: ./your_program.sh tokenize <filename>")
      exit(1)
    }
  }
}

pub fn handle_tokenize(
  filename: String
) -> Result(Nil, FileError) {
  use contents <- result.try(simplifile.read(filename))
  tokenize(contents) |> print
  Ok(Nil)
}
