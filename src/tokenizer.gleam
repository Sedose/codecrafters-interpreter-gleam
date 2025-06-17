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
  StringToken(String)
  Eof
}

pub type TokenizationError {
  UnrecognizedChar(line_number: Int, unexpected_char: String)
  UnterminatedString(line_number: Int)
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
      TokenizationResult(
        list.reverse([Eof, ..tokens_rev]),
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
    ["!", "=", ..rest] -> scan(line, rest, [BangEqual, ..tokens_rev], errors)
    ["=", "=", ..rest] -> scan(line, rest, [EqualEqual, ..tokens_rev], errors)
    ["<", "=", ..rest] -> scan(line, rest, [LessEqual, ..tokens_rev], errors)
    [">", "=", ..rest] -> scan(line, rest, [GreaterEqual, ..tokens_rev], errors)
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

fn scan_string(
  line: Int,
  chars: List(String),
  literal_rev: List(String),
  tokens_rev: List(Token),
  errors: List(TokenizationError),
) -> TokenizationResult {
  case chars {
    [] -> scan(line, chars, tokens_rev, [UnterminatedString(line), ..errors])
    ["\"", ..after_quote] -> {
      let literal = literal_rev |> list.reverse |> string.concat
      scan(line, after_quote, [StringToken(literal), ..tokens_rev], errors)
    }
    ["\n", ..rest] ->
      scan_string(line + 1, rest, ["\n", ..literal_rev], tokens_rev, errors)
    [ch, ..rest] ->
      scan_string(line, rest, [ch, ..literal_rev], tokens_rev, errors)
  }
}
