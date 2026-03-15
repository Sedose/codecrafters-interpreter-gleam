import data_def.{
  type BinaryOp, type Expr, type ParseError, type Token, type TokenWithLine,
  type UnaryOp, AddOp, Bang, BangEqual, Binary, DivideOp, Eof, EqualEqual,
  EqualEqualOp, FalseLiteral, FalseToken, Greater, GreaterEqual, GreaterEqualOp,
  GreaterOp, Grouping, Identifier, LeftParen, Less, LessEqual, LessEqualOp,
  LessOp, Literal, Minus, MultiplyOp, NegateOp, NilLiteral, NilToken, NotEqualOp,
  NotOp, Number, NumberLiteral, ParseErrorAtEnd, ParseErrorAtToken, Plus,
  RightParen, Slash, Star, String, StringLiteral, SubtractOp, TokenWithLine,
  TrueLiteral, TrueToken, Unary, Variable,
}
import gleam/list
import gleam/result

type OperatorParseResult(op) {
  Operator(op: op, rest: List(TokenWithLine))
  NoOperator
}

pub fn parse(tokens: List(Token)) -> Result(Expr, ParseError) {
  tokens
  |> to_tokens_with_default_line([], 1)
  |> list.reverse
  |> parse_with_rest
  |> result.try(assert_expression_end)
}

pub fn parse_with_rest(
  tokens: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  parse_expression(tokens)
}

fn to_tokens_with_default_line(
  tokens: List(Token),
  tokens_with_line_rev: List(TokenWithLine),
  line: Int,
) -> List(TokenWithLine) {
  case tokens {
    [] -> tokens_with_line_rev
    [token, ..rest] ->
      to_tokens_with_default_line(
        rest,
        [TokenWithLine(token, line), ..tokens_with_line_rev],
        line,
      )
  }
}

fn assert_expression_end(
  parsed: #(Expr, List(TokenWithLine)),
) -> Result(Expr, ParseError) {
  let #(expr, rest) = parsed

  case rest {
    [TokenWithLine(Eof, _)] -> Ok(expr)
    [] -> Ok(expr)
    [TokenWithLine(token, _), ..] ->
      Error(ParseErrorAtToken(token, "Expect end of expression."))
  }
}

fn parse_expression(
  tokens: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  parse_equality(tokens)
}

fn parse_equality(
  tokens: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  parse_left_associative(tokens, parse_comparison, parse_equality_op)
}

fn parse_comparison(
  tokens: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  parse_left_associative(tokens, parse_term, parse_comparison_op)
}

fn parse_term(
  tokens: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  parse_left_associative(tokens, parse_factor, parse_term_op)
}

fn parse_factor(
  tokens: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  parse_left_associative(tokens, parse_unary, parse_factor_op)
}

fn parse_left_associative(
  tokens: List(TokenWithLine),
  parse_operand: fn(List(TokenWithLine)) ->
    Result(#(Expr, List(TokenWithLine)), ParseError),
  parse_operator: fn(List(TokenWithLine)) -> OperatorParseResult(BinaryOp),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  case parse_operand(tokens) {
    Ok(#(left, rest)) ->
      parse_left_associative_tail(left, rest, parse_operand, parse_operator)
    Error(error) -> Error(error)
  }
}

fn parse_left_associative_tail(
  left: Expr,
  tokens: List(TokenWithLine),
  parse_operand: fn(List(TokenWithLine)) ->
    Result(#(Expr, List(TokenWithLine)), ParseError),
  parse_operator: fn(List(TokenWithLine)) -> OperatorParseResult(BinaryOp),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  case parse_operator(tokens) {
    Operator(op, after_op) ->
      case parse_operand(after_op) {
        Ok(#(right, rest)) ->
          parse_left_associative_tail(
            Binary(op, left, right),
            rest,
            parse_operand,
            parse_operator,
          )
        Error(error) -> Error(error)
      }
    NoOperator -> Ok(#(left, tokens))
  }
}

fn parse_equality_op(
  tokens: List(TokenWithLine),
) -> OperatorParseResult(BinaryOp) {
  case tokens {
    [TokenWithLine(EqualEqual, _), ..rest] -> Operator(EqualEqualOp, rest)
    [TokenWithLine(BangEqual, _), ..rest] -> Operator(NotEqualOp, rest)
    _ -> NoOperator
  }
}

fn parse_comparison_op(
  tokens: List(TokenWithLine),
) -> OperatorParseResult(BinaryOp) {
  case tokens {
    [TokenWithLine(Greater, _), ..rest] -> Operator(GreaterOp, rest)
    [TokenWithLine(GreaterEqual, _), ..rest] -> Operator(GreaterEqualOp, rest)
    [TokenWithLine(Less, _), ..rest] -> Operator(LessOp, rest)
    [TokenWithLine(LessEqual, _), ..rest] -> Operator(LessEqualOp, rest)
    _ -> NoOperator
  }
}

fn parse_term_op(tokens: List(TokenWithLine)) -> OperatorParseResult(BinaryOp) {
  case tokens {
    [TokenWithLine(Plus, _), ..rest] -> Operator(AddOp, rest)
    [TokenWithLine(Minus, _), ..rest] -> Operator(SubtractOp, rest)
    _ -> NoOperator
  }
}

fn parse_factor_op(tokens: List(TokenWithLine)) -> OperatorParseResult(BinaryOp) {
  case tokens {
    [TokenWithLine(Star, _), ..rest] -> Operator(MultiplyOp, rest)
    [TokenWithLine(Slash, _), ..rest] -> Operator(DivideOp, rest)
    _ -> NoOperator
  }
}

fn parse_unary(
  tokens: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  case parse_unary_prefix(tokens) {
    Operator(op, rest) ->
      case parse_unary(rest) {
        Ok(#(expr, remaining)) -> Ok(#(Unary(op, expr), remaining))
        Error(error) -> Error(error)
      }
    NoOperator -> parse_primary(tokens)
  }
}

fn parse_unary_prefix(
  tokens: List(TokenWithLine),
) -> OperatorParseResult(UnaryOp) {
  case tokens {
    [TokenWithLine(Bang, _), ..rest] -> Operator(NotOp, rest)
    [TokenWithLine(Minus, _), ..rest] -> Operator(NegateOp, rest)
    _ -> NoOperator
  }
}

fn parse_primary(
  tokens: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  case tokens {
    [TokenWithLine(TrueToken, _), ..rest] -> Ok(#(Literal(TrueLiteral), rest))
    [TokenWithLine(FalseToken, _), ..rest] -> Ok(#(Literal(FalseLiteral), rest))
    [TokenWithLine(NilToken, _), ..rest] -> Ok(#(Literal(NilLiteral), rest))
    [TokenWithLine(Number(_, value), _), ..rest] ->
      Ok(#(Literal(NumberLiteral(value)), rest))
    [TokenWithLine(String(s), _), ..rest] ->
      Ok(#(Literal(StringLiteral(s)), rest))
    [TokenWithLine(Identifier(name), _), ..rest] -> Ok(#(Variable(name), rest))
    [TokenWithLine(LeftParen, _), ..after_lparen] ->
      parse_grouping(after_lparen)
    [TokenWithLine(Eof, _), ..] -> Error(ParseErrorAtEnd("Expect expression."))
    [TokenWithLine(token, _), ..] ->
      Error(ParseErrorAtToken(token, "Expect expression."))
    [] -> Error(ParseErrorAtEnd("Expect expression."))
  }
}

fn parse_grouping(
  after_lparen: List(TokenWithLine),
) -> Result(#(Expr, List(TokenWithLine)), ParseError) {
  case parse_expression(after_lparen) {
    Ok(#(inner, [TokenWithLine(RightParen, _), ..after_rparen])) ->
      Ok(#(Grouping(inner), after_rparen))
    Ok(#(_, [TokenWithLine(Eof, _), ..])) ->
      Error(ParseErrorAtEnd("Expect ')' after expression."))
    Ok(#(_, [TokenWithLine(token, _), ..])) ->
      Error(ParseErrorAtToken(token, "Expect ')' after expression."))
    Ok(#(_, [])) -> Error(ParseErrorAtEnd("Expect ')' after expression."))
    Error(error) -> Error(error)
  }
}
