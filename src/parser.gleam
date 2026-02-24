import data_def.{type Expr, type ParseError, type Statement, type Token, type TokenWithLine}
import parser/expression
import parser/program

pub fn parse(tokens: List(Token)) -> Result(Expr, ParseError) {
  expression.parse(tokens)
}

pub fn parse_program(
  tokens: List(TokenWithLine),
) -> Result(List(Statement), ParseError) {
  program.parse_program(tokens)
}
