import gleam/list
import gleam/option.{type Option, None, Some}
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

pub type Pending {
  NonePending
  EqualPending
}

pub type TokenizerState {
  TokenizerState(
    line: Int,
    tokens: List(Token),
    errors: List(TokenizationError),
    pending: Pending,
  )
}

pub fn tokenize(source: String) -> TokenizationResult {
  let initial_state = TokenizerState(1, [], [], NonePending)
  let final_state =
    string.to_graphemes(source)
    |> list.fold(initial_state, classify_fold)
  let TokenizerState(_, tokens0, errors, pending) = final_state
  let tokens1 = case pending {
    EqualPending -> tokens0 |> list.append([Equal])
    NonePending -> tokens0
  }
  TokenizationResult(tokens1 |> list.append([Eof]), errors)
}

fn classify_fold(state: TokenizerState, ch: String) -> TokenizerState {
  case state {
    TokenizerState(line, tokens, errors, pending) ->
      case pending {
        EqualPending -> handle_after_equal(line, tokens, errors, ch)
        NonePending -> handle_char(line, tokens, errors, ch)
      }
  }
}

fn handle_after_equal(
  line: Int,
  tokens: List(Token),
  errors: List(TokenizationError),
  ch: String,
) -> TokenizerState {
  case ch {
    "=" -> {
      let t = tokens |> list.append([EqualEqual])
      TokenizerState(line, t, errors, NonePending)
    }
    _ -> {
      let t_with_eq = tokens |> list.append([Equal])
      handle_char(line, t_with_eq, errors, ch)
    }
  }
}

fn handle_char(
  line: Int,
  tokens: List(Token),
  errors: List(TokenizationError),
  ch: String,
) -> TokenizerState {
  case ch {
    "=" -> TokenizerState(line, tokens, errors, EqualPending)

    _ ->
      case classify_char(ch) {
        Some(NewLine) -> TokenizerState(line + 1, tokens, errors, NonePending)

        Some(token) ->
          TokenizerState(
            line,
            tokens |> list.append([token]),
            errors,
            NonePending,
          )

        None ->
          TokenizerState(
            line,
            tokens,
            errors |> list.append([UnrecognizedChar(line, ch)]),
            NonePending,
          )
      }
  }
}

fn classify_char(ch: String) -> Option(Token) {
  case ch {
    "\n" -> Some(NewLine)
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
    _ -> None
  }
}
