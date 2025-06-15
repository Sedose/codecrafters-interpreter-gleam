import gleam/list
import gleam/string
import line_number.{type LineNumber, from_int}

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
  NewLine
  Eof
}

pub type TokenizationError {
  TokenizationErrorData(line_number: LineNumber, unexpected_char: String)
}

pub type TokenizationResult {
  TokenizationResult(tokens: List(Token), errors: List(TokenizationError))
}

pub fn tokenize(source: String) -> TokenizationResult {
  let graphemes = string.to_graphemes(source)
  scan_characters_recursive(graphemes, 1, [], [])
}

fn scan_characters_recursive(
  graphemes: List(String),
  line_number: Int,
  collected_tokens: List(Token),
  collected_errors: List(TokenizationError),
) -> TokenizationResult {
  case graphemes {
    [] ->
      TokenizationResult(list.append(collected_tokens, [Eof]), collected_errors)
    [char, ..rest] -> {
      case classify_char(char) {
        Ok([NewLine]) -> {
          scan_characters_recursive(
            rest,
            line_number + 1,
            collected_tokens,
            collected_errors,
          )
        }
        Ok(recognized_token) -> {
          let updated_tokens = list.append(collected_tokens, recognized_token)
          scan_characters_recursive(
            rest,
            line_number,
            updated_tokens,
            collected_errors,
          )
        }
        Error(_) -> {
          let updated_errors =
            list.append(collected_errors, [
              TokenizationErrorData(from_int(line_number), char),
            ])
          scan_characters_recursive(
            rest,
            line_number,
            collected_tokens,
            updated_errors,
          )
        }
      }
    }
  }
}

fn classify_char(char: String) -> Result(List(Token), Nil) {
  case char {
    "(" -> Ok([LeftParen])
    ")" -> Ok([RightParen])
    "{" -> Ok([LeftBrace])
    "}" -> Ok([RightBrace])
    "+" -> Ok([Plus])
    "-" -> Ok([Minus])
    "," -> Ok([Comma])
    "." -> Ok([Dot])
    ";" -> Ok([Semicolon])
    "*" -> Ok([Star])
    "/" -> Ok([Slash])
    "\n" -> Ok([NewLine])
    _ -> Error(Nil)
  }
}
