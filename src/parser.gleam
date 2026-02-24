import data_def.{
  type BinaryOp, type Expr, type OperatorParseResult, type ParseError,
  type Statement, type Token, type TokenWithLine, type UnaryOp, AddOp, Bang,
  BangEqual, Binary, DivideOp, Eof, Equal, EqualEqual, EqualEqualOp,
  ExpressionStatement, FalseLiteral, FalseToken, Greater, GreaterEqual,
  GreaterEqualOp, GreaterOp, Grouping, Identifier, LeftParen, Less, LessEqual,
  LessEqualOp, LessOp, Literal, Minus, MultiplyOp, NegateOp, NilLiteral,
  NilToken, NoOperator, NotEqualOp, NotOp, Number, NumberLiteral, Operator,
  ParseErrorAtEnd, ParseErrorAtToken, Plus, Print, PrintStatement, RightParen,
  Semicolon, Slash, Star, String, StringLiteral, SubtractOp, TokenWithLine,
  TrueLiteral, TrueToken, Unary, Var, VarStatement, Variable,
}
import gleam/list

pub fn parse(tokens: List(Token)) -> Result(Expr, ParseError) {
  case parse_expression(tokens) {
    Ok(#(expr, [Eof])) -> Ok(expr)
    Ok(#(expr, [])) -> Ok(expr)
    Ok(#(_, [token, ..])) ->
      Error(ParseErrorAtToken(token, "Expect end of expression."))
    Error(error) -> Error(error)
  }
}

pub fn parse_program(
  tokens: List(TokenWithLine),
) -> Result(List(Statement), ParseError) {
  parse_statements(tokens, [])
}

fn parse_statements(
  tokens: List(TokenWithLine),
  statements_rev: List(Statement),
) -> Result(List(Statement), ParseError) {
  case tokens {
    [TokenWithLine(Eof, _)] -> Ok(statements_rev |> list.reverse)
    [] -> Ok(statements_rev |> list.reverse)
    _ ->
      case parse_statement(tokens) {
        Ok(#(statement, rest)) ->
          parse_statements(rest, [statement, ..statements_rev])
        Error(error) -> Error(error)
      }
  }
}

fn parse_statement(
  tokens: List(TokenWithLine),
) -> Result(#(Statement, List(TokenWithLine)), ParseError) {
  case tokens {
    [TokenWithLine(Var, line), ..after_var] ->
      parse_var_statement(line, after_var)
    [TokenWithLine(Print, line), ..after_print] ->
      parse_print_statement(line, after_print)
    [TokenWithLine(_, line), ..] -> parse_expression_statement(line, tokens)
    [] -> Error(ParseErrorAtEnd("Expect statement."))
  }
}

fn parse_var_statement(
  line: Int,
  tokens: List(TokenWithLine),
) -> Result(#(Statement, List(TokenWithLine)), ParseError) {
  case tokens {
    [TokenWithLine(Identifier(name), _), TokenWithLine(Semicolon, _), ..rest] ->
      Ok(#(VarStatement(line, name, Literal(NilLiteral)), rest))
    [TokenWithLine(Identifier(name), _), TokenWithLine(Equal, _), ..after_equal] ->
      case
        take_until_semicolon(
          after_equal,
          [],
          "Expect ';' after variable declaration.",
        )
      {
        Ok(#(initializer_tokens_with_lines, rest)) ->
          case parse(initializer_tokens_with_lines |> to_tokens) {
            Ok(initializer) ->
              Ok(#(VarStatement(line, name, initializer), rest))
            Error(error) -> Error(error)
          }
        Error(error) -> Error(error)
      }
    [TokenWithLine(Identifier(_), _), TokenWithLine(token, _), ..] ->
      Error(ParseErrorAtToken(token, "Expect ';' after variable declaration."))
    [TokenWithLine(Identifier(_), _)] ->
      Error(ParseErrorAtEnd("Expect ';' after variable declaration."))
    [TokenWithLine(token, _), ..] ->
      Error(ParseErrorAtToken(token, "Expect variable name."))
    [] -> Error(ParseErrorAtEnd("Expect variable name."))
  }
}

fn parse_print_statement(
  line: Int,
  tokens: List(TokenWithLine),
) -> Result(#(Statement, List(TokenWithLine)), ParseError) {
  case tokens {
    [TokenWithLine(Semicolon, _), ..] ->
      Error(ParseErrorAtToken(Semicolon, "Expect expression."))
    _ ->
      case take_until_semicolon(tokens, [], "Expect ';' after value.") {
        Ok(#(expression_tokens_with_lines, rest)) ->
          case parse(expression_tokens_with_lines |> to_tokens) {
            Ok(expression) -> Ok(#(PrintStatement(line, expression), rest))
            Error(error) -> Error(error)
          }
        Error(error) -> Error(error)
      }
  }
}

fn parse_expression_statement(
  line: Int,
  tokens: List(TokenWithLine),
) -> Result(#(Statement, List(TokenWithLine)), ParseError) {
  case take_until_semicolon(tokens, [], "Expect ';' after expression.") {
    Ok(#(expression_tokens_with_lines, rest)) ->
      case parse(expression_tokens_with_lines |> to_tokens) {
        Ok(expression) -> Ok(#(ExpressionStatement(line, expression), rest))
        Error(error) -> Error(error)
      }
    Error(error) -> Error(error)
  }
}

fn take_until_semicolon(
  tokens: List(TokenWithLine),
  statement_tokens_rev: List(TokenWithLine),
  missing_semicolon_message: String,
) -> Result(#(List(TokenWithLine), List(TokenWithLine)), ParseError) {
  case tokens {
    [TokenWithLine(Semicolon, _), ..rest] ->
      Ok(#(statement_tokens_rev |> list.reverse, rest))
    [TokenWithLine(Eof, _)] -> Error(ParseErrorAtEnd(missing_semicolon_message))
    [token, ..rest] ->
      take_until_semicolon(
        rest,
        [token, ..statement_tokens_rev],
        missing_semicolon_message,
      )
    [] -> Error(ParseErrorAtEnd(missing_semicolon_message))
  }
}

fn to_tokens(tokens_with_lines: List(TokenWithLine)) -> List(Token) {
  tokens_with_lines
  |> list.map(fn(token_with_line) {
    case token_with_line {
      TokenWithLine(token, _) -> token
    }
  })
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
  case parse_operand(tokens) {
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
  case parse_unary_prefix(tokens) {
    Operator(op, rest) ->
      case parse_unary(rest) {
        Ok(#(expr, remaining)) -> Ok(#(Unary(op, expr), remaining))
        Error(error) -> Error(error)
      }
    NoOperator -> parse_primary(tokens)
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
    [Identifier(name), ..rest] -> Ok(#(Variable(name), rest))
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
