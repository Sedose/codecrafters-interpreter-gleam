pub type Expr {
  Literal(LiteralValue)
}

pub type LiteralValue {
  TrueLiteral
  FalseLiteral
  NilLiteral
  NumberLiteral(Float)
  StringLiteral(String)
}
