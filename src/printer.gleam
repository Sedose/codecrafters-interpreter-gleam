import gleam/float
import gleam/int
import gleam/io
import gleam/list

import tokenizer.{
  type Token, type TokenizationError, type TokenizationResult, And, Bang,
  BangEqual, Class, Comma, Dot, Else, Eof, Equal, EqualEqual, FalseToken, For,
  Fun, Greater, GreaterEqual, Identifier, If, LeftBrace, LeftParen, Less,
  LessEqual, Minus, NilToken, Number, Or, Plus, Print, Return, RightBrace,
  RightParen, Semicolon, Slash, Star, String, Super, This, TrueToken,
  UnrecognizedChar, UnterminatedString, Var, While,
}

pub fn print(result: TokenizationResult) -> Nil {
  result.errors
  |> list.map(format_error)
  |> list.map(io.println_error)

  result.tokens
  |> list.map(format_token)
  |> list.map(io.println)

  Nil
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
    Slash -> "SLASH / null"
    Eof -> "EOF  null"
    Bang -> "BANG ! null"
    BangEqual -> "BANG_EQUAL != null"
    Greater -> "GREATER > null"
    GreaterEqual -> "GREATER_EQUAL >= null"
    Less -> "LESS < null"
    LessEqual -> "LESS_EQUAL <= null"
    String(literal) -> {
      let lexeme = "\"" <> literal <> "\""
      "STRING " <> lexeme <> " " <> literal
    }
    Number(lexeme, value) ->
      "NUMBER " <> lexeme <> " " <> float.to_string(value)

    Identifier(name) -> "IDENTIFIER " <> name <> " null"
    And -> "AND and null"
    Class -> "CLASS class null"
    Else -> "ELSE else null"
    For -> "FOR for null"
    Fun -> "FUN fun null"
    If -> "IF if null"
    NilToken -> "NIL nil null"
    Or -> "OR or null"
    Print -> "PRINT print null"
    Return -> "RETURN return null"
    Super -> "SUPER super null"
    This -> "THIS this null"
    TrueToken -> "TRUE true null"
    FalseToken -> "FALSE false null"
    Var -> "VAR var null"
    While -> "WHILE while null"
  }
}

fn format_error(error: TokenizationError) -> String {
  case error {
    UnrecognizedChar(line_number, unexpected_char) ->
      "[line "
      <> int.to_string(line_number)
      <> "] Error: Unexpected character: "
      <> unexpected_char

    UnterminatedString(line_number) ->
      "[line " <> int.to_string(line_number) <> "] Error: Unterminated string."
  }
}
