import gleam/list
import gleam/option.{type Option, None, Some}
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
  NewLine
  Eof
}

pub type TokenizationError {
  UnrecognizedChar(line_number: Int, unexpected_char: String)
}

pub type TokenizationResult {
  TokenizationResult(tokens: List(Token), errors: List(TokenizationError))
}

pub type TokenizerState {
  TokenizerState(
    line: Int,
    tokens: List(Token),
    errors: List(TokenizationError),
  )
}

pub fn tokenize(source: String) -> TokenizationResult {
  let initial_state = TokenizerState(1, [], [])

  let final_state =
    string.to_graphemes(source)
    |> list.fold(initial_state, classify_fold)

  let TokenizerState(_, tokens, errors) = final_state
  TokenizationResult(tokens |> list.append([Eof]), errors)
}

fn classify_fold(state: TokenizerState, char: String) -> TokenizerState {
  case state {
    TokenizerState(line, tokens, errors) ->
      case classify_char(char) {
        Some(NewLine) -> TokenizerState(line + 1, tokens, errors)

        Some(token) -> {
          let updated_tokens = tokens |> list.append([token])
          TokenizerState(line, updated_tokens, errors)
        }

        None -> {
          let updated_errors =
            errors |> list.append([UnrecognizedChar(line, char)])
          TokenizerState(line, tokens, updated_errors)
        }
      }
  }
}

fn classify_char(char: String) -> Option(Token) {
  case char {
    "(" -> Some(LeftParen)
    ")" -> Some(RightParen)
    "{" -> Some(LeftBrace)
    "}" -> Some(RightBrace)
    "+" -> Some(Plus)
    "-" -> Some(Minus)
    "," -> Some(Comma)
    "." -> Some(Dot)
    ";" -> Some(Semicolon)
    "*" -> Some(Star)
    "/" -> Some(Slash)
    "\n" -> Some(NewLine)
    _ -> None
  }
}
