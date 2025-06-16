import gleam/list
import gleam/string

// Using `Result(token, Nil)` rather than `Option` to follow Gleam idioms
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

/// Public entry point. Scans the source string into tokens or collects errors.
/// Builds the token list *in reverse* for linear‐time appends, then reverses once.
/// No intermediate `Pending` state is needed—multi‑character tokens are matched
/// up‑front via list pattern matching.
pub fn tokenize(source: String) -> TokenizationResult {
  let graphemes = string.to_graphemes(source)
  scan(1, graphemes, [], [])
}

/// Tail‑recursive scanner. `tokens_rev` and `errors` grow by pre‑pending.
fn scan(
  line: Int,
  chars: List(String),
  tokens_rev: List(Token),
  errors: List(TokenizationError),
) -> TokenizationResult {
  case chars {
    // ── End of input ──────────────────────────────────────────────────────────
    [] -> {
      let tokens = list.reverse([Eof, ..tokens_rev])
      TokenizationResult(tokens, errors)
    }
    // ── Two‑character token ──────────────────────────────────────────────────
    ["=", "=", ..rest] ->
      scan(line, rest, [EqualEqual, ..tokens_rev], errors)

    // ── Single‑character tokens & newline handling ───────────────────────────
    ["\n", ..rest] ->
      scan(line + 1, rest, [NewLine, ..tokens_rev], errors)

    ["=", ..rest] ->
      scan(line, rest, [Equal, ..tokens_rev], errors)
    ["(", ..rest] ->
      scan(line, rest, [LeftParen, ..tokens_rev], errors)
    [")", ..rest] ->
      scan(line, rest, [RightParen, ..tokens_rev], errors)
    ["{", ..rest] ->
      scan(line, rest, [LeftBrace, ..tokens_rev], errors)
    ["}", ..rest] ->
      scan(line, rest, [RightBrace, ..tokens_rev], errors)
    [",", ..rest] ->
      scan(line, rest, [Comma, ..tokens_rev], errors)
    [".", ..rest] ->
      scan(line, rest, [Dot, ..tokens_rev], errors)
    ["-", ..rest] ->
      scan(line, rest, [Minus, ..tokens_rev], errors)
    ["+", ..rest] ->
      scan(line, rest, [Plus, ..tokens_rev], errors)
    [";", ..rest] ->
      scan(line, rest, [Semicolon, ..tokens_rev], errors)
    ["*", ..rest] ->
      scan(line, rest, [Star, ..tokens_rev], errors)
    ["/", ..rest] ->
      scan(line, rest, [Slash, ..tokens_rev], errors)

    // ── Anything else is unrecognised ────────────────────────────────────────
    [ch, ..rest] ->
      scan(
        line,
        rest,
        tokens_rev,
        [UnrecognizedChar(line, ch), ..errors],
      )
  }
}
