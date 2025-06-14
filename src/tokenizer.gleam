import gleam/list
import gleam/string

pub type Token {
  LeftParen(value: String)
  RightParen(value: String)
  LeftBrace(value: String)
  RightBrace(value: String)
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
        "(" -> list.append(collected, [LeftParen(char)])
        ")" -> list.append(collected, [RightParen(char)])
        "{" -> list.append(collected, [LeftBrace(char)])
        "}" -> list.append(collected, [RightBrace(char)])
        _ -> collected
      }
      scan_characters_recursive(rest, new_collected)
    }
  }
}
