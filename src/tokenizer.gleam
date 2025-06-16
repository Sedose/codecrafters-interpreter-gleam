import gleam/list
import gleam/string

pub type Token {
  Bang
  Equal
  LeftParen
  RightParen
  LeftBrace
  RightBrace
  Comma
  Dot
  Minus
  Plus
  Semicolon
  Slash
  Star
  BangEqual
  EqualEqual
  LessEqual
  GreaterEqual
  Less
  Greater
  Eof
}

pub type TokenizationError {
  UnrecognizedChar(line_number: Int, unexpected_char: String)
}

pub type TokenizationResult {
  TokenizationResult(tokens: List(Token), errors: List(TokenizationError))
}

pub fn tokenize(source: String) -> TokenizationResult {
  let graphemes = string.to_graphemes(source)
  scan(1, graphemes, [], [])
}

fn scan(
  line: Int,
  chars: List(String),
  tokens_rev: List(Token),
  errors: List(TokenizationError),
) -> TokenizationResult {
  case chars {
    [] -> 
      TokenizationResult(list.reverse([Eof, ..tokens_rev]), list.reverse(errors))
    ["\r", "\n", ..rest] ->
      scan(line + 1, rest, tokens_rev, errors)
    ["\n", ..rest] ->
      scan(line + 1, rest, tokens_rev, errors)
    [" ", ..rest] -> scan(line, rest, tokens_rev, errors)
    ["\t", ..rest] -> scan(line, rest, tokens_rev, errors)
    ["\r", ..rest] -> scan(line, rest, tokens_rev, errors)
    ["/", "/", ..rest] ->
      skip_comment(line, rest, tokens_rev, errors)
    ["!", "=", ..rest] ->
      scan(line, rest, [BangEqual, ..tokens_rev], errors)
    ["=", "=", ..rest] ->
      scan(line, rest, [EqualEqual, ..tokens_rev], errors)
    ["<", "=", ..rest] ->
      scan(line, rest, [LessEqual, ..tokens_rev], errors)
    [">", "=", ..rest] ->
      scan(line, rest, [GreaterEqual, ..tokens_rev], errors)
    ["!", ..rest] -> scan(line, rest, [Bang, ..tokens_rev], errors)
    ["=", ..rest] -> scan(line, rest, [Equal, ..tokens_rev], errors)
    ["<", ..rest] -> scan(line, rest, [Less, ..tokens_rev], errors)
    [">", ..rest] -> scan(line, rest, [Greater, ..tokens_rev], errors)
    ["(", ..rest] -> scan(line, rest, [LeftParen, ..tokens_rev], errors)
    [")", ..rest] -> scan(line, rest, [RightParen, ..tokens_rev], errors)
    ["{", ..rest] -> scan(line, rest, [LeftBrace, ..tokens_rev], errors)
    ["}", ..rest] -> scan(line, rest, [RightBrace, ..tokens_rev], errors)
    [",", ..rest] -> scan(line, rest, [Comma, ..tokens_rev], errors)
    [".", ..rest] -> scan(line, rest, [Dot, ..tokens_rev], errors)
    ["-", ..rest] -> scan(line, rest, [Minus, ..tokens_rev], errors)
    ["+", ..rest] -> scan(line, rest, [Plus, ..tokens_rev], errors)
    [";", ..rest] -> scan(line, rest, [Semicolon, ..tokens_rev], errors)
    ["*", ..rest] -> scan(line, rest, [Star, ..tokens_rev], errors)
    ["/", ..rest] -> scan(line, rest, [Slash, ..tokens_rev], errors)
    [ch, ..rest] ->
      scan(line, rest, tokens_rev, [UnrecognizedChar(line, ch), ..errors])
  }
}

fn skip_comment(
  line: Int,
  chars: List(String),
  tokens_rev: List(Token),
  errors: List(TokenizationError),
) -> TokenizationResult {
  case chars {
    [] -> scan(line, [], tokens_rev, errors)
    ["\r", "\n", ..rest] -> scan(line + 1, rest, tokens_rev, errors)
    ["\n", ..rest] -> scan(line + 1, rest, tokens_rev, errors)
    [_, ..rest] -> skip_comment(line, rest, tokens_rev, errors)
  }
}
