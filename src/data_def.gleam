pub type Token {
  Bang
  Equal
  LeftParen
  RightParen
  LeftBrace
  RightBrace
  Comma
  Dot
  Minus
  Plus
  Semicolon
  Slash
  Star
  BangEqual
  EqualEqual
  LessEqual
  GreaterEqual
  Less
  Greater
  String(value: String)
  Number(lexeme: String, value: Float)
  Identifier(name: String)
  And
  Class
  Else
  For
  Fun
  If
  NilToken
  Or
  Print
  Return
  Super
  This
  TrueToken
  FalseToken
  Var
  While
  Eof
}

pub type UnaryOp {
  NotOp
  NegateOp
}

pub type BinaryOp {
  MultiplyOp
  DivideOp
  AddOp
  SubtractOp
  GreaterOp
  GreaterEqualOp
  LessOp
  LessEqualOp
  EqualEqualOp
  NotEqualOp
}

pub type Expr {
  Literal(value: LiteralValue)
  Grouping(inner: Expr)
  Unary(op: UnaryOp, right: Expr)
  Binary(op: BinaryOp, left: Expr, right: Expr)
}

pub type LiteralValue {
  TrueLiteral
  FalseLiteral
  NilLiteral
  NumberLiteral(Float)
  StringLiteral(String)
}

pub type TokenizationError {
  UnrecognizedChar(line_number: Int, unexpected_char: String)
  UnterminatedString(line_number: Int)
}

pub type TokenizationResult {
  TokenizationResult(tokens: List(Token), errors: List(TokenizationError))
}

pub type ParseError {
  ParseErrorAtToken(token: Token, message: String)
  ParseErrorAtEnd(message: String)
}

pub type OperatorParseResult(op) {
  Operator(op: op, rest: List(Token))
  NoOperator
}
