import gleam/list
import argv
import external_things.{exit}
import gleam/io
import printer.{print}
import simplifile
import tokenizer.{tokenize}

pub fn main() -> Nil {
  case argv.load().arguments {
    ["tokenize", filename] -> handle_tokenize(filename)
    _ -> {
      io.println_error("Usage: ./your_program.sh tokenize <filename>")
      exit(1)
    }
  }
}

fn handle_tokenize(filename: String) -> Nil {
  case simplifile.read(filename) {
    Ok(contents) -> {
      let tokenization_result = tokenize(contents)
      print(tokenization_result)
      case  tokenization_result.errors |> list.is_empty {
        True -> Nil
        False -> exit(65)
      }
    }

    Error(error) -> io.println_error(simplifile.describe_error(error))
  }
}
