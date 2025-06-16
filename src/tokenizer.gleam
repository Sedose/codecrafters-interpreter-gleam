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
    line:   Int,
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
        Ok(NewLine) ->
          TokenizerState(line + 1, tokens, errors)

        Ok(token) -> {
          let updated_tokens = tokens |> list.append([token])
          TokenizerState(line, updated_tokens, errors)
        }

        Error(_) -> {
          let updated_errors =
            errors |> list.append([UnrecognizedChar(line, char)])
          TokenizerState(line, tokens, updated_errors)
        }
      }
  }
}

fn classify_char(char: String) -> Result(Token, Nil) {
  case char {
    "("  -> Ok(LeftParen)
    ")"  -> Ok(RightParen)
    "{"  -> Ok(LeftBrace)
    "}"  -> Ok(RightBrace)
    "+"  -> Ok(Plus)
    "-"  -> Ok(Minus)
    ","  -> Ok(Comma)
    "."  -> Ok(Dot)
    ";"  -> Ok(Semicolon)
    "*"  -> Ok(Star)
    "/"  -> Ok(Slash)
    "\n" -> Ok(NewLine)
    _    -> Error(Nil)
  }
}
