import data_def.{type Expr, type InterpretationResult, type LiteralValue, type Statement}
import evaluator/expression
import evaluator/format as literal_format
import evaluator/program

pub fn interpret(statements: List(Statement)) -> InterpretationResult {
  program.interpret(statements)
}

pub fn evaluate(expression_input: Expr) -> Result(LiteralValue, String) {
  expression.evaluate(expression_input)
}

pub fn format(value: LiteralValue) -> String {
  literal_format.format(value)
}
