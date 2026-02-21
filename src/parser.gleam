import data_def.{
  type BinaryOp, type Expr, type OperatorParseResult, type ParseError,
  type Token, type UnaryOp, AddOp, Bang, BangEqual, Binary, DivideOp, Eof,
  EqualEqual, EqualEqualOp, FalseLiteral, FalseToken, Greater, GreaterEqual,
  GreaterEqualOp, GreaterOp, Grouping, LeftParen, Less, LessEqual, LessEqualOp,
  LessOp, Literal, Minus, MultiplyOp, NegateOp, NilLiteral, NilToken, NoOperator,
  NotEqualOp, NotOp, Number, NumberLiteral, Operator, ParseErrorAtEnd,
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
  parse_left_associative(tokens, parse_comparison, parse_equality_op)
}

fn parse_comparison(
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  parse_left_associative(tokens, parse_term, parse_comparison_op)
}

fn parse_term(tokens: List(Token)) -> Result(#(Expr, List(Token)), ParseError) {
  parse_left_associative(tokens, parse_factor, parse_term_op)
}

fn parse_factor(tokens: List(Token)) -> Result(#(Expr, List(Token)), ParseError) {
  parse_left_associative(tokens, parse_unary, parse_factor_op)
}

fn parse_left_associative(
  tokens: List(Token),
  parse_operand: fn(List(Token)) -> Result(#(Expr, List(Token)), ParseError),
  parse_operator: fn(List(Token)) -> OperatorParseResult(BinaryOp),
) -> Result(#(Expr, List(Token)), ParseError) {
  tokens
  |> parse_operand
  |> resolve_left_operand(parse_operand, parse_operator)
}

fn resolve_left_operand(
  parsed_operand: Result(#(Expr, List(Token)), ParseError),
  parse_operand: fn(List(Token)) -> Result(#(Expr, List(Token)), ParseError),
  parse_operator: fn(List(Token)) -> OperatorParseResult(BinaryOp),
) -> Result(#(Expr, List(Token)), ParseError) {
  case parsed_operand {
    Ok(#(left, rest)) ->
      parse_left_associative_tail(left, rest, parse_operand, parse_operator)
    Error(error) -> Error(error)
  }
}

fn parse_left_associative_tail(
  left: Expr,
  tokens: List(Token),
  parse_operand: fn(List(Token)) -> Result(#(Expr, List(Token)), ParseError),
  parse_operator: fn(List(Token)) -> OperatorParseResult(BinaryOp),
) -> Result(#(Expr, List(Token)), ParseError) {
  tokens
  |> parse_operator
  |> resolve_left_operator(left, tokens, parse_operand, parse_operator)
}

fn resolve_left_operator(
  parsed_operator: OperatorParseResult(BinaryOp),
  left: Expr,
  tokens: List(Token),
  parse_operand: fn(List(Token)) -> Result(#(Expr, List(Token)), ParseError),
  parse_operator: fn(List(Token)) -> OperatorParseResult(BinaryOp),
) -> Result(#(Expr, List(Token)), ParseError) {
  case parsed_operator {
    Operator(op, after_op) ->
      after_op
      |> parse_operand
      |> build_left_associative(op, left, parse_operand, parse_operator)
    NoOperator -> Ok(#(left, tokens))
  }
}

fn build_left_associative(
  parsed_right_operand: Result(#(Expr, List(Token)), ParseError),
  op: BinaryOp,
  left: Expr,
  parse_operand: fn(List(Token)) -> Result(#(Expr, List(Token)), ParseError),
  parse_operator: fn(List(Token)) -> OperatorParseResult(BinaryOp),
) -> Result(#(Expr, List(Token)), ParseError) {
  case parsed_right_operand {
    Ok(#(right, rest)) ->
      parse_left_associative_tail(
        Binary(op, left, right),
        rest,
        parse_operand,
        parse_operator,
      )
    Error(error) -> Error(error)
  }
}

fn parse_equality_op(tokens: List(Token)) -> OperatorParseResult(BinaryOp) {
  case tokens {
    [EqualEqual, ..rest] -> Operator(EqualEqualOp, rest)
    [BangEqual, ..rest] -> Operator(NotEqualOp, rest)
    _ -> NoOperator
  }
}

fn parse_comparison_op(tokens: List(Token)) -> OperatorParseResult(BinaryOp) {
  case tokens {
    [Greater, ..rest] -> Operator(GreaterOp, rest)
    [GreaterEqual, ..rest] -> Operator(GreaterEqualOp, rest)
    [Less, ..rest] -> Operator(LessOp, rest)
    [LessEqual, ..rest] -> Operator(LessEqualOp, rest)
    _ -> NoOperator
  }
}

fn parse_term_op(tokens: List(Token)) -> OperatorParseResult(BinaryOp) {
  case tokens {
    [Plus, ..rest] -> Operator(AddOp, rest)
    [Minus, ..rest] -> Operator(SubtractOp, rest)
    _ -> NoOperator
  }
}

fn parse_factor_op(tokens: List(Token)) -> OperatorParseResult(BinaryOp) {
  case tokens {
    [Star, ..rest] -> Operator(MultiplyOp, rest)
    [Slash, ..rest] -> Operator(DivideOp, rest)
    _ -> NoOperator
  }
}

fn parse_unary(tokens: List(Token)) -> Result(#(Expr, List(Token)), ParseError) {
  tokens |> parse_unary_prefix |> resolve_unary_prefix(tokens)
}

fn resolve_unary_prefix(
  parsed_prefix: OperatorParseResult(UnaryOp),
  tokens: List(Token),
) -> Result(#(Expr, List(Token)), ParseError) {
  case parsed_prefix {
    Operator(op, rest) -> rest |> parse_unary |> build_unary(op)
    NoOperator -> parse_primary(tokens)
  }
}

fn build_unary(
  parsed_unary: Result(#(Expr, List(Token)), ParseError),
  op: UnaryOp,
) -> Result(#(Expr, List(Token)), ParseError) {
  case parsed_unary {
    Ok(#(expr, remaining)) -> Ok(#(Unary(op, expr), remaining))
    Error(error) -> Error(error)
  }
}

fn parse_unary_prefix(tokens: List(Token)) -> OperatorParseResult(UnaryOp) {
  case tokens {
    [Bang, ..rest] -> Operator(NotOp, rest)
    [Minus, ..rest] -> Operator(NegateOp, rest)
    _ -> NoOperator
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
