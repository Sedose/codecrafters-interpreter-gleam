import argv
import external_things.{exit}
import gleam/io
import simplifile
import tokenizer.{
  type Token, Eof, LeftBrace, LeftParen, RightBrace, RightParen, tokenize,
}

pub fn main() -> Nil {
  case argv.load().arguments {
    ["tokenize", filename] -> {
      case simplifile.read(filename) {
        Ok(contents) -> {
          tokenize(contents)
          |> print_tokens
        }
        Error(error) -> {
          io.println_error(simplifile.describe_error(error))
        }
      }
    }
    _ -> {
      io.println_error("Usage: ./your_program.sh tokenize <filename>")
      exit(1)
    }
  }
}

fn print_tokens(tokens: List(Token)) -> Nil {
  case tokens {
    [] -> Nil
    [token, ..rest] -> {
      io.println(case token {
        LeftParen(c) -> "LEFT_PAREN " <> c <> " null"
        RightParen(c) -> "RIGHT_PAREN " <> c <> " null"
        LeftBrace(c) -> "LEFT_BRACE " <> c <> " null"
        RightBrace(c) -> "RIGHT_BRACE " <> c <> " null"
        Eof -> "EOF  null"
      })
      print_tokens(rest)
    }
  }
}
