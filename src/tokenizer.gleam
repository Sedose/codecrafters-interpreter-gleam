import gleam/list
import gleam/string

pub type Token {
  Equal
  EqualEqual
  LeftParen
  RightParen
  LeftBrace
  RightBrace
  Comma
  Dot
  Minus
  Plus
  Semicolon
  Star
  Slash
  NewLine
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
    [] -> {
      let tokens = list.reverse([Eof, ..tokens_rev])
      TokenizationResult(tokens, errors)
    }
    ["=", "=", ..rest] -> scan(line, rest, [EqualEqual, ..tokens_rev], errors)
    ["\n", ..rest] -> scan(line + 1, rest, [NewLine, ..tokens_rev], errors)
    ["=", ..rest] -> scan(line, rest, [Equal, ..tokens_rev], errors)
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

    // ── Anything else is unrecognised ────────────────────────────────────────
    [ch, ..rest] ->
      scan(line, rest, tokens_rev, [UnrecognizedChar(line, ch), ..errors])
  }
}
