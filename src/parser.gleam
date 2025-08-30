import ast.{
  type Expr, FalseLiteral, Literal, NilLiteral, NumberLiteral, StringLiteral,
  TrueLiteral,
}
import tokenizer.{type Token, FalseToken, NilToken, Number, String, TrueToken}

pub fn parse(tokens: List(Token)) -> Expr {
  case tokens {
    [TrueToken, ..] -> Literal(TrueLiteral)
    [FalseToken, ..] -> Literal(FalseLiteral)
    [NilToken, ..] -> Literal(NilLiteral)
    [Number(_, value), ..] -> Literal(NumberLiteral(value))
    [String(s), ..] -> Literal(StringLiteral(s))
    _ -> Literal(NilLiteral)
  }
}
