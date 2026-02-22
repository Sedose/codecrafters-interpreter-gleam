import data_def.{
  type Token, type TokenWithLine, type TokenizationError,
  type TokenizationResult, type TokenizationResultWithLines, And, Bang,
  BangEqual, Class, Comma, Dot, Else, Eof, Equal, EqualEqual, FalseToken, For,
  Fun, Greater, GreaterEqual, Identifier, If, LeftBrace, LeftParen, Less,
  LessEqual, Minus, NilToken, Number, Or, Plus, Print, Return, RightBrace,
  RightParen, Semicolon, Slash, Star, String, Super, This, TokenWithLine,
  TokenizationResult, TokenizationResultWithLines, TrueToken, UnrecognizedChar,
  UnterminatedString, Var, While,
}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import util.{is_alpha, is_alpha_numeric, is_digit, is_number_char}

pub fn tokenize(source: String) -> TokenizationResult {
  case tokenize_with_lines(source) {
    TokenizationResultWithLines(tokens: tokens_with_lines, errors: errors) ->
      TokenizationResult(
        tokens: tokens_with_lines |> list.map(token_without_line),
        errors: errors,
      )
  }
}

pub fn tokenize_with_lines(source: String) -> TokenizationResultWithLines {
  let graphemes = string.to_graphemes(source)
  scan(1, graphemes, [], [])
}

fn token_without_line(token_with_line: TokenWithLine) -> Token {
  case token_with_line {
    TokenWithLine(token, _) -> token
  }
}

fn scan(
  line: Int,
  chars: List(String),
  tokens_rev: List(TokenWithLine),
  errors: List(TokenizationError),
) -> TokenizationResultWithLines {
  case chars {
    [] ->
      TokenizationResultWithLines(
        list.reverse([TokenWithLine(Eof, line), ..tokens_rev]),
        list.reverse(errors),
      )
    ["\r", "\n", ..rest] -> scan(line + 1, rest, tokens_rev, errors)
    ["\n", ..rest] -> scan(line + 1, rest, tokens_rev, errors)
    [" ", ..rest] -> scan(line, rest, tokens_rev, errors)
    ["\t", ..rest] -> scan(line, rest, tokens_rev, errors)
    ["\"", ..rest] -> scan_string(line, rest, [], tokens_rev, errors)
    ["/", "/", ..rest] -> {
      let after_comment =
        rest |> list.drop_while(fn(ch) { ch != "\n" && ch != "\r" })
      scan(line, after_comment, tokens_rev, errors)
    }
    ["!", "=", ..rest] ->
      scan(line, rest, [TokenWithLine(BangEqual, line), ..tokens_rev], errors)
    ["=", "=", ..rest] ->
      scan(line, rest, [TokenWithLine(EqualEqual, line), ..tokens_rev], errors)
    ["<", "=", ..rest] ->
      scan(line, rest, [TokenWithLine(LessEqual, line), ..tokens_rev], errors)
    [">", "=", ..rest] ->
      scan(
        line,
        rest,
        [TokenWithLine(GreaterEqual, line), ..tokens_rev],
        errors,
      )
    ["!", ..rest] ->
      scan(line, rest, [TokenWithLine(Bang, line), ..tokens_rev], errors)
    ["=", ..rest] ->
      scan(line, rest, [TokenWithLine(Equal, line), ..tokens_rev], errors)
    ["<", ..rest] ->
      scan(line, rest, [TokenWithLine(Less, line), ..tokens_rev], errors)
    [">", ..rest] ->
      scan(line, rest, [TokenWithLine(Greater, line), ..tokens_rev], errors)
    ["(", ..rest] ->
      scan(line, rest, [TokenWithLine(LeftParen, line), ..tokens_rev], errors)
    [")", ..rest] ->
      scan(line, rest, [TokenWithLine(RightParen, line), ..tokens_rev], errors)
    ["{", ..rest] ->
      scan(line, rest, [TokenWithLine(LeftBrace, line), ..tokens_rev], errors)
    ["}", ..rest] ->
      scan(line, rest, [TokenWithLine(RightBrace, line), ..tokens_rev], errors)
    [",", ..rest] ->
      scan(line, rest, [TokenWithLine(Comma, line), ..tokens_rev], errors)
    [".", ..rest] ->
      scan(line, rest, [TokenWithLine(Dot, line), ..tokens_rev], errors)
    ["-", ..rest] ->
      scan(line, rest, [TokenWithLine(Minus, line), ..tokens_rev], errors)
    ["+", ..rest] ->
      scan(line, rest, [TokenWithLine(Plus, line), ..tokens_rev], errors)
    [";", ..rest] ->
      scan(line, rest, [TokenWithLine(Semicolon, line), ..tokens_rev], errors)
    ["*", ..rest] ->
      scan(line, rest, [TokenWithLine(Star, line), ..tokens_rev], errors)
    ["/", ..rest] ->
      scan(line, rest, [TokenWithLine(Slash, line), ..tokens_rev], errors)
    [char, ..rest] -> {
      case is_digit(char) {
        True -> scan_number(line, [char, ..rest], tokens_rev, errors)
        False ->
          case is_alpha(char) {
            True -> scan_identifier(line, [char, ..rest], tokens_rev, errors)
            False ->
              scan(line, rest, tokens_rev, [
                UnrecognizedChar(line, char),
                ..errors
              ])
          }
      }
    }
  }
}

fn scan_string(
  line: Int,
  chars: List(String),
  literal_rev: List(String),
  tokens_rev: List(TokenWithLine),
  errors: List(TokenizationError),
) -> TokenizationResultWithLines {
  case chars {
    [] -> scan(line, chars, tokens_rev, [UnterminatedString(line), ..errors])
    ["\"", ..after_quote] -> {
      let literal = literal_rev |> list.reverse |> string.concat
      scan(
        line,
        after_quote,
        [TokenWithLine(String(literal), line), ..tokens_rev],
        errors,
      )
    }
    ["\n", ..rest] ->
      scan_string(line + 1, rest, ["\n", ..literal_rev], tokens_rev, errors)
    [ch, ..rest] ->
      scan_string(line, rest, [ch, ..literal_rev], tokens_rev, errors)
  }
}

fn scan_number(
  line: Int,
  chars: List(String),
  tokens_rev: List(TokenWithLine),
  errors: List(TokenizationError),
) -> TokenizationResultWithLines {
  let digits = list.take_while(chars, is_number_char)
  let remaining = list.drop_while(chars, is_number_char)
  let lexeme = string.concat(digits)
  case parse_number(lexeme) {
    Ok(value) -> {
      let updated_tokens_rev = [
        TokenWithLine(Number(lexeme, value), line),
        ..tokens_rev
      ]
      scan(line, remaining, updated_tokens_rev, errors)
    }
    Error(_) -> {
      let updated_errors_rev = [UnrecognizedChar(line, lexeme), ..errors]
      scan(line, remaining, tokens_rev, updated_errors_rev)
    }
  }
}

fn parse_number(lexeme: String) -> Result(Float, Nil) {
  result.or(
    float.parse(lexeme),
    int.parse(lexeme)
      |> result.map(int.to_float),
  )
}

fn scan_identifier(
  line: Int,
  chars: List(String),
  tokens_rev: List(TokenWithLine),
  errors: List(TokenizationError),
) -> TokenizationResultWithLines {
  let glyphs = list.take_while(chars, is_alpha_numeric)
  let remaining = list.drop_while(chars, is_alpha_numeric)
  let lexeme = string.concat(glyphs)
  let token = keyword_or_identifier(lexeme)
  scan(line, remaining, [TokenWithLine(token, line), ..tokens_rev], errors)
}

fn keyword_or_identifier(lexeme: String) -> Token {
  case lexeme {
    "and" -> And
    "class" -> Class
    "else" -> Else
    "false" -> FalseToken
    "for" -> For
    "fun" -> Fun
    "if" -> If
    "nil" -> NilToken
    "or" -> Or
    "print" -> Print
    "return" -> Return
    "super" -> Super
    "this" -> This
    "true" -> TrueToken
    "var" -> Var
    "while" -> While
    _ -> Identifier(lexeme)
  }
}
