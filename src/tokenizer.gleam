import gleam/list
import gleam/string

pub type Token {
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
  Eof
}

pub fn tokenize(source: String) -> List(Token) {
  let graphemes = string.to_graphemes(source)
  scan_characters_recursive(graphemes, [])
}

fn scan_characters_recursive(
  graphemes: List(String),
  collected: List(Token),
) -> List(Token) {
  case graphemes {
    [] -> list.append(collected, [Eof])
    [char, ..rest] -> {
      let updated = list.append(collected, classify_char(char))
      scan_characters_recursive(rest, updated)
    }
  }
}

fn classify_char(char: String) -> List(Token) {
  case char {
    "(" -> [LeftParen]
    ")" -> [RightParen]
    "{" -> [LeftBrace]
    "}" -> [RightBrace]
    "+" -> [Plus]
    "-" -> [Minus]
    "," -> [Comma]
    "." -> [Dot]
    ";" -> [Semicolon]
    "*" -> [Star]
    "/" -> [Slash]
    _   -> []
  }
}
