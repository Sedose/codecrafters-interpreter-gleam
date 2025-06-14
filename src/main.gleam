import argv
import external_things.{exit}
import gleam/io
import simplifile
import tokenizer.{
  type Token, Comma, Dot, Eof, LeftBrace, LeftParen, Minus, Plus, RightBrace,
  RightParen, Semicolon, Slash, Star, tokenize,
}

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
      tokenize(contents)
      |> print_tokens
    Error(error) ->
      io.println_error(simplifile.describe_error(error))
  }
}

fn print_tokens(tokens: List(Token)) -> Nil {
  case tokens {
    [] -> Nil
    [first, ..rest] -> {
      format_token(first) |> io.println
      print_tokens(rest)
    }
  }
}

fn format_token(token: Token) -> String {
  case token {
    LeftParen  -> "LEFT_PAREN ( null"
    RightParen -> "RIGHT_PAREN ) null"
    LeftBrace  -> "LEFT_BRACE { null"
    RightBrace -> "RIGHT_BRACE } null"
    Comma      -> "COMMA , null"
    Dot        -> "DOT . null"
    Minus      -> "MINUS - null"
    Semicolon  -> "SEMICOLON ; null"
    Plus       -> "PLUS + null"
    Star       -> "STAR * null"
    Slash      -> "DIVIDE / null"
    Eof        -> "EOF  null"
  }
}
