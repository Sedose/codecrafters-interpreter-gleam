import argv
import external_things.{exit}
import gleam/io
import simplifile
import tokenizer.{tokenize}
import printer.{print_tokens}

pub fn main() -> Nil {
  case argv.load().arguments {
    ["tokenize", filename] ->
      handle_tokenize(filename)
    _ -> {
      io.println_error("Usage: ./your_program.sh tokenize <filename>")
      exit(1)
    }
  }
}

fn handle_tokenize(filename: String) -> Nil {
  case simplifile.read(filename) {
    Ok(contents) ->
      contents
      |> tokenize
      |> print_tokens

    Error(error) ->
      io.println_error(simplifile.describe_error(error))
  }
}
