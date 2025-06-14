import gleam/io
import tokenizer.{
  type Token,
  Comma,
  Dot,
  Eof,
  LeftBrace,
  LeftParen,
  Minus,
  Plus,
  RightBrace,
  RightParen,
  Semicolon,
  Slash,
  Star,
}

pub fn print_tokens(tokens: List(Token)) -> Nil {
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
