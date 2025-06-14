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
      let new_collected = case char {
        "(" -> list.append(collected, [LeftParen])
        ")" -> list.append(collected, [RightParen])
        "{" -> list.append(collected, [LeftBrace])
        "}" -> list.append(collected, [RightBrace])
        "+" -> list.append(collected, [Plus])
        "-" -> list.append(collected, [Minus])
        "," -> list.append(collected, [Comma])
        "." -> list.append(collected, [Dot])
        ";" -> list.append(collected, [Semicolon])
        "*" -> list.append(collected, [Star])
        "/" -> list.append(collected, [Slash])
        _ -> collected
      }
      scan_characters_recursive(rest, new_collected)
    }
  }
}
