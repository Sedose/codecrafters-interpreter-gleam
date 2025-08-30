import ast.{type Expr, FalseLiteral, Literal, NilLiteral, TrueLiteral}
import tokenizer.{type Token, FalseToken, NilToken, TrueToken}

pub fn parse(tokens: List(Token)) -> Expr {
  case tokens {
    [TrueToken, ..] -> Literal(TrueLiteral)
    [FalseToken, ..] -> Literal(FalseLiteral)
    [NilToken, ..] -> Literal(NilLiteral)
    _ -> Literal(NilLiteral)
  }
}
