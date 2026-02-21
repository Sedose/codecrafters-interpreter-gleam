import data_def.{
  type Expr, type ParseError, type Token, AddOp, Bang, BangEqual, Binary,
  DivideOp, Eof, EqualEqual, EqualEqualOp, FalseLiteral, FalseToken, Greater,
  GreaterEqual, GreaterEqualOp, GreaterOp, Grouping, LeftParen, Less, LessEqual,
  LessEqualOp, LessOp, Literal, Minus, MultiplyOp, NegateOp, NilLiteral,
  NilToken, NotEqualOp, NotOp, Number, NumberLiteral, ParseErrorAtEnd,
  ParseErrorAtToken, Plus, RightParen, Slash, Star, String, StringLiteral,
  SubtractOp, TrueLiteral, TrueToken, Unary,
}

pub fn parse(tokens: List(Token)) -> Result(Expr, ParseError) {
  case parse_expression(tokens) {
    Ok(#(expr, [Eof])) -> Ok(expr)
    Ok(#(expr, [])) -> Ok(expr)
    Ok(#(_, [token, ..])) ->
      Error(ParseErrorAtToken(token, "Expect end of expression."))
    Error(error) -> Error(error)
  }
}

fn parse_expression(
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  parse_equality(tokens)
}

fn parse_equality(
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case parse_comparison(tokens) {
    Ok(#(left, rest)) -> parse_equality_tail(left, rest)
    Error(error) -> Error(error)
  }
}

fn parse_equality_tail(
  left: Expr,
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case tokens {
    [EqualEqual, ..after_op] -> {
      case parse_comparison(after_op) {
        Ok(#(right, rest)) ->
          parse_equality_tail(Binary(EqualEqualOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    [BangEqual, ..after_op] -> {
      case parse_comparison(after_op) {
        Ok(#(right, rest)) ->
          parse_equality_tail(Binary(NotEqualOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    _ -> Ok(#(left, tokens))
  }
}

fn parse_comparison(
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case parse_term(tokens) {
    Ok(#(left, rest)) -> parse_comparison_tail(left, rest)
    Error(error) -> Error(error)
  }
}

fn parse_comparison_tail(
  left: Expr,
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case tokens {
    [Greater, ..after_op] -> {
      case parse_term(after_op) {
        Ok(#(right, rest)) ->
          parse_comparison_tail(Binary(GreaterOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    [GreaterEqual, ..after_op] -> {
      case parse_term(after_op) {
        Ok(#(right, rest)) ->
          parse_comparison_tail(Binary(GreaterEqualOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    [Less, ..after_op] -> {
      case parse_term(after_op) {
        Ok(#(right, rest)) ->
          parse_comparison_tail(Binary(LessOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    [LessEqual, ..after_op] -> {
      case parse_term(after_op) {
        Ok(#(right, rest)) ->
          parse_comparison_tail(Binary(LessEqualOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    _ -> Ok(#(left, tokens))
  }
}

fn parse_term(tokens: List(Token)) -> Result(#(Expr, List(Token)), ParseError) {
  case parse_factor(tokens) {
    Ok(#(left, rest)) -> parse_term_tail(left, rest)
    Error(error) -> Error(error)
  }
}

fn parse_term_tail(
  left: Expr,
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case tokens {
    [Plus, ..after_op] -> {
      case parse_factor(after_op) {
        Ok(#(right, rest)) -> parse_term_tail(Binary(AddOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    [Minus, ..after_op] -> {
      case parse_factor(after_op) {
        Ok(#(right, rest)) ->
          parse_term_tail(Binary(SubtractOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    _ -> Ok(#(left, tokens))
  }
}

fn parse_factor(tokens: List(Token)) -> Result(#(Expr, List(Token)), ParseError) {
  case parse_unary(tokens) {
    Ok(#(left, rest)) -> parse_factor_tail(left, rest)
    Error(error) -> Error(error)
  }
}

fn parse_factor_tail(
  left: Expr,
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case tokens {
    [Star, ..after_op] -> {
      case parse_unary(after_op) {
        Ok(#(right, rest)) ->
          parse_factor_tail(Binary(MultiplyOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    [Slash, ..after_op] -> {
      case parse_unary(after_op) {
        Ok(#(right, rest)) ->
          parse_factor_tail(Binary(DivideOp, left, right), rest)
        Error(error) -> Error(error)
      }
    }
    _ -> Ok(#(left, tokens))
  }
}

fn parse_unary(tokens: List(Token)) -> Result(#(Expr, List(Token)), ParseError) {
  case tokens {
    [Bang, ..rest] -> {
      case parse_unary(rest) {
        Ok(#(expr, remaining)) -> Ok(#(Unary(NotOp, expr), remaining))
        Error(error) -> Error(error)
      }
    }
    [Minus, ..rest] -> {
      case parse_unary(rest) {
        Ok(#(expr, remaining)) -> Ok(#(Unary(NegateOp, expr), remaining))
        Error(error) -> Error(error)
      }
    }
    _ -> parse_primary(tokens)
  }
}

fn parse_primary(
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case tokens {
    [TrueToken, ..rest] -> Ok(#(Literal(TrueLiteral), rest))
    [FalseToken, ..rest] -> Ok(#(Literal(FalseLiteral), rest))
    [NilToken, ..rest] -> Ok(#(Literal(NilLiteral), rest))
    [Number(_, value), ..rest] -> Ok(#(Literal(NumberLiteral(value)), rest))
    [String(s), ..rest] -> Ok(#(Literal(StringLiteral(s)), rest))
    [LeftParen, ..after_lparen] -> parse_grouping(after_lparen)
    [Eof, ..] -> Error(ParseErrorAtEnd("Expect expression."))
    [token, ..] -> Error(ParseErrorAtToken(token, "Expect expression."))
    [] -> Error(ParseErrorAtEnd("Expect expression."))
  }
}

fn parse_grouping(
  after_lparen: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case parse_expression(after_lparen) {
    Ok(#(inner, [RightParen, ..after_rparen])) ->
      Ok(#(Grouping(inner), after_rparen))
    Ok(#(_, [Eof, ..])) ->
      Error(ParseErrorAtEnd("Expect ')' after expression."))
    Ok(#(_, [token, ..])) ->
      Error(ParseErrorAtToken(token, "Expect ')' after expression."))
    Ok(#(_, [])) -> Error(ParseErrorAtEnd("Expect ')' after expression."))
    Error(error) -> Error(error)
  }
}
