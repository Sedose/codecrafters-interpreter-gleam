import data_def.{
  type ParseError, type Statement, type Token, type TokenWithLine, Eof, Equal,
  ExpressionStatement, Identifier, Literal, NilLiteral, ParseErrorAtEnd,
  ParseErrorAtToken, Print, PrintStatement, Semicolon, TokenWithLine, Var,
  VarStatement,
}
import gleam/list
import parser/expression.{parse}

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
