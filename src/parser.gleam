import data_def.{
  type BinaryOp, type Expr, type Token, AddOp, Bang, BangEqual, Binary, DivideOp,
  EqualEqual, EqualEqualOp, FalseLiteral, FalseToken, Greater, GreaterEqual,
  GreaterEqualOp, GreaterOp, Grouping, LeftParen, Less, LessEqual, LessEqualOp,
  LessOp, Literal, Minus, MultiplyOp, NegateOp, NilLiteral, NilToken, NotEqualOp,
  NotOp, Number, NumberLiteral, Plus, RightParen, Slash, Star, String,
  StringLiteral, SubtractOp, TrueLiteral, TrueToken, Unary,
}

pub fn parse(tokens: List(Token)) -> Expr {
  case parse_expression(tokens) {
    Done(expr, _) -> expr
  }
}

fn parse_expression(tokens: List(Token)) -> ParseResult {
  parse_equality(tokens)
}

fn parse_equality(tokens: List(Token)) -> ParseResult {
  let Done(left, rest) = parse_comparison(tokens)
  parse_equality_tail(left, rest)
}

fn parse_equality_tail(left: Expr, tokens: List(Token)) -> ParseResult {
  case tokens {
    [EqualEqual, ..after_op] -> {
      let Done(right, rest) = parse_comparison(after_op)
      parse_equality_tail(Binary(EqualEqualOp, left, right), rest)
    }
    [BangEqual, ..after_op] -> {
      let Done(right, rest) = parse_comparison(after_op)
      parse_equality_tail(Binary(NotEqualOp, left, right), rest)
    }
    _ -> Done(left, tokens)
  }
}

fn parse_comparison(tokens: List(Token)) -> ParseResult {
  let Done(left, rest) = parse_term(tokens)
  parse_comparison_tail(left, rest)
}

fn parse_comparison_tail(left: Expr, tokens: List(Token)) -> ParseResult {
  case tokens {
    [Greater, ..after_op] -> {
      let Done(right, rest) = parse_term(after_op)
      parse_comparison_tail(Binary(GreaterOp, left, right), rest)
    }
    [GreaterEqual, ..after_op] -> {
      let Done(right, rest) = parse_term(after_op)
      parse_comparison_tail(Binary(GreaterEqualOp, left, right), rest)
    }
    [Less, ..after_op] -> {
      let Done(right, rest) = parse_term(after_op)
      parse_comparison_tail(Binary(LessOp, left, right), rest)
    }
    [LessEqual, ..after_op] -> {
      let Done(right, rest) = parse_term(after_op)
      parse_comparison_tail(Binary(LessEqualOp, left, right), rest)
    }
    _ -> Done(left, tokens)
  }
}

fn parse_term(tokens: List(Token)) -> ParseResult {
  let Done(left, rest) = parse_factor(tokens)
  parse_term_tail(left, rest)
}

fn parse_term_tail(left: Expr, tokens: List(Token)) -> ParseResult {
  case tokens {
    [Plus, ..after_op] -> {
      let Done(right, rest) = parse_factor(after_op)
      parse_term_tail(Binary(AddOp, left, right), rest)
    }
    [Minus, ..after_op] -> {
      let Done(right, rest) = parse_factor(after_op)
      parse_term_tail(Binary(SubtractOp, left, right), rest)
    }
    _ -> Done(left, tokens)
  }
}

fn parse_factor(tokens: List(Token)) -> ParseResult {
  let Done(left, rest) = parse_unary(tokens)
  parse_factor_tail(left, rest)
}

fn parse_factor_tail(left: Expr, tokens: List(Token)) -> ParseResult {
  case tokens {
    [Star, ..after_op] -> {
      let Done(right, rest) = parse_unary(after_op)
      parse_factor_tail(Binary(MultiplyOp, left, right), rest)
    }
    [Slash, ..after_op] -> {
      let Done(right, rest) = parse_unary(after_op)
      parse_factor_tail(Binary(DivideOp, left, right), rest)
    }
    _ -> Done(left, tokens)
  }
}

fn parse_unary(tokens: List(Token)) -> ParseResult {
  case tokens {
    [Bang, ..rest] -> {
      let Done(expr, remaining) = parse_unary(rest)
      Done(Unary(NotOp, expr), remaining)
    }
    [Minus, ..rest] -> {
      let Done(expr, remaining) = parse_unary(rest)
      Done(Unary(NegateOp, expr), remaining)
    }
    _ -> parse_primary(tokens)
  }
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
