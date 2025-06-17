import gleam/int
import gleam/io
import tokenizer.{
  type Token, type TokenizationError, type TokenizationResult, Bang, BangEqual,
  Comma, Dot, Eof, Equal, EqualEqual, Greater, GreaterEqual, LeftBrace,
  LeftParen, Less, LessEqual, Minus, Plus, RightBrace, RightParen, Semicolon,
  Slash, Star,
}

pub fn print(tokenization_result: TokenizationResult) -> Nil {
  tokenization_result.errors |> print_errors
  tokenization_result.tokens |> print_tokens
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
    Equal -> "EQUAL = null"
    EqualEqual -> "EQUAL_EQUAL == null"
    LeftParen -> "LEFT_PAREN ( null"
    RightParen -> "RIGHT_PAREN ) null"
    LeftBrace -> "LEFT_BRACE { null"
    RightBrace -> "RIGHT_BRACE } null"
    Comma -> "COMMA , null"
    Dot -> "DOT . null"
    Minus -> "MINUS - null"
    Semicolon -> "SEMICOLON ; null"
    Plus -> "PLUS + null"
    Star -> "STAR * null"
    Slash -> "DIVIDE / null"
    Eof -> "EOF  null"
    Bang -> "BANG ! null"
    BangEqual -> "BANG_EQUAL != null"
    Greater -> "GREATER > null"
    GreaterEqual -> "GREATER_EQUAL >= null"
    Less -> "LESS < null"
    LessEqual -> "LESS_EQUAL <= null"
  }
}

fn print_errors(errors: List(TokenizationError)) -> Nil {
  case errors {
    [] -> Nil
    [first, ..rest] -> {
      format_error(first) |> io.println_error
      print_errors(rest)
    }
  }
}

fn format_error(error: TokenizationError) -> String {
  let line_number = error.line_number |> int.to_string
  let unexpected_char = error.unexpected_char
  "[line "
  <> line_number
  <> "] Error: Unexpected character: "
  <> unexpected_char
}
