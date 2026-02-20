import data_def.{
  type ParseError, type Token, And, Bang, BangEqual, Class, Comma, Dot, Else,
  Eof, Equal, EqualEqual, FalseToken, For, Fun, Greater, GreaterEqual,
  Identifier, If, LeftBrace, LeftParen, Less, LessEqual, Minus, NilToken, Number,
  Or, ParseErrorAtEnd, ParseErrorAtToken, Plus, Print, Return, RightBrace,
  RightParen, Semicolon, Slash, Star, String, Super, This, TrueToken, Var, While,
}

pub fn format_error(error: ParseError) -> String {
  case error {
    ParseErrorAtToken(token, message) ->
      "[line 1] Error at '" <> token_lexeme(token) <> "': " <> message
    ParseErrorAtEnd(message) -> "[line 1] Error at end: " <> message
  }
}

fn token_lexeme(token: Token) -> String {
  case token {
    Bang -> "!"
    Equal -> "="
    LeftParen -> "("
    RightParen -> ")"
    LeftBrace -> "{"
    RightBrace -> "}"
    Comma -> ","
    Dot -> "."
    Minus -> "-"
    Plus -> "+"
    Semicolon -> ";"
    Slash -> "/"
    Star -> "*"
    BangEqual -> "!="
    EqualEqual -> "=="
    LessEqual -> "<="
    GreaterEqual -> ">="
    Less -> "<"
    Greater -> ">"
    String(value) -> value
    Number(lexeme, _) -> lexeme
    Identifier(name) -> name
    And -> "and"
    Class -> "class"
    Else -> "else"
    For -> "for"
    Fun -> "fun"
    If -> "if"
    NilToken -> "nil"
    Or -> "or"
    Print -> "print"
    Return -> "return"
    Super -> "super"
    This -> "this"
    TrueToken -> "true"
    FalseToken -> "false"
    Var -> "var"
    While -> "while"
    Eof -> ""
  }
}
