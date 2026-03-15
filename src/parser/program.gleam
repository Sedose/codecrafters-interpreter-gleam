import data_def.{
  type ParseError, type Statement, type TokenWithLine, Eof, Equal,
  ExpressionStatement, Identifier, Literal, NilLiteral, ParseErrorAtEnd,
  ParseErrorAtToken, Print, PrintStatement, Semicolon, TokenWithLine, Var,
  VarStatement,
}
import gleam/list
import parser/expression.{parse_with_rest}

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
    [TokenWithLine(Identifier(name), _), ..after_name] ->
      parse_var_initializer(line, name, after_name)
    [TokenWithLine(token, _), ..] ->
      Error(ParseErrorAtToken(token, "Expect variable name."))
    [] -> Error(ParseErrorAtEnd("Expect variable name."))
  }
}

fn parse_var_initializer(
  line: Int,
  name: String,
  tokens: List(TokenWithLine),
) -> Result(#(Statement, List(TokenWithLine)), ParseError) {
  case tokens {
    [TokenWithLine(Semicolon, _), ..rest] ->
      Ok(#(VarStatement(line, name, Literal(NilLiteral)), rest))
    [TokenWithLine(Equal, _), ..after_equal] ->
      case
        parse_expression_and_expect_semicolon(
          after_equal,
          "Expect ';' after variable declaration.",
        )
      {
        Ok(#(initializer, rest)) ->
          Ok(#(VarStatement(line, name, initializer), rest))
        Error(error) -> Error(error)
      }
    [TokenWithLine(token, _), ..] ->
      Error(ParseErrorAtToken(token, "Expect ';' after variable declaration."))
    [] -> Error(ParseErrorAtEnd("Expect ';' after variable declaration."))
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
      case
        parse_expression_and_expect_semicolon(tokens, "Expect ';' after value.")
      {
        Ok(#(expression, rest)) -> Ok(#(PrintStatement(line, expression), rest))
        Error(error) -> Error(error)
      }
  }
}

fn parse_expression_statement(
  line: Int,
  tokens: List(TokenWithLine),
) -> Result(#(Statement, List(TokenWithLine)), ParseError) {
  case
    parse_expression_and_expect_semicolon(
      tokens,
      "Expect ';' after expression.",
    )
  {
    Ok(#(expression, rest)) ->
      Ok(#(ExpressionStatement(line, expression), rest))
    Error(error) -> Error(error)
  }
}

fn parse_expression_and_expect_semicolon(
  tokens: List(TokenWithLine),
  missing_semicolon_message: String,
) -> Result(#(data_def.Expr, List(TokenWithLine)), ParseError) {
  case parse_with_rest(tokens) {
    Ok(#(expression, [TokenWithLine(Semicolon, _), ..rest])) ->
      Ok(#(expression, rest))
    Ok(#(_, [TokenWithLine(Eof, _)])) ->
      Error(ParseErrorAtEnd(missing_semicolon_message))
    Ok(#(_, [])) -> Error(ParseErrorAtEnd(missing_semicolon_message))
    Ok(#(_, [TokenWithLine(token, _), ..])) ->
      Error(ParseErrorAtToken(token, missing_semicolon_message))
    Error(error) -> Error(error)
  }
}
