import data_def.{
  type Expr, type Token, FalseLiteral, FalseToken, Grouping, LeftParen, Literal,
  NilLiteral, NilToken, Number, NumberLiteral, RightParen, String, StringLiteral,
  TrueLiteral, TrueToken,
}

pub fn parse(tokens: List(Token)) -> Expr {
  case parse_expression(tokens) {
    Done(expr, _) -> expr
  }
}

fn parse_expression(tokens: List(Token)) -> ParseResult {
  parse_primary(tokens)
}

fn parse_primary(tokens: List(Token)) -> ParseResult {
  case tokens {
    [TrueToken, ..rest] -> Done(Literal(TrueLiteral), rest)
    [FalseToken, ..rest] -> Done(Literal(FalseLiteral), rest)
    [NilToken, ..rest] -> Done(Literal(NilLiteral), rest)
    [Number(_, value), ..rest] -> Done(Literal(NumberLiteral(value)), rest)
    [String(s), ..rest] -> Done(Literal(StringLiteral(s)), rest)
    [LeftParen, ..after_lparen] -> {
      let Done(inner, after_inner) = parse_expression(after_lparen)
      case after_inner {
        [RightParen, ..after_rparen] -> Done(Grouping(inner), after_rparen)
        _ -> Done(Grouping(inner), after_inner)
      }
    }
    _ -> Done(Literal(NilLiteral), tokens)
  }
}

type ParseResult {
  Done(expr: Expr, rest: List(Token))
}
