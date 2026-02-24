import data_def.{
  type InterpretationResult, type RuntimeError, type Statement, Completed,
  ExpressionStatement, Failed, PrintStatement, RuntimeError, VarStatement,
}
import evaluator/expression.{type Environment, empty_environment, evaluate_in}
import evaluator/format
import gleam/dict
import gleam/list
import gleam/result

type ProgramState {
  ProgramState(outputs_rev: List(String), environment: Environment)
}

pub fn interpret(statements: List(Statement)) -> InterpretationResult {
  interpret_statements(
    statements,
    ProgramState(outputs_rev: [], environment: empty_environment()),
  )
}

fn interpret_statements(
  statements: List(Statement),
  state: ProgramState,
) -> InterpretationResult {
  case statements {
    [] -> Completed(state.outputs_rev |> list.reverse)
    [statement, ..rest] ->
      case interpret_statement(statement, state) {
        Ok(next_state) -> interpret_statements(rest, next_state)
        Error(error) ->
          Failed(outputs: state.outputs_rev |> list.reverse, error: error)
      }
  }
}

fn interpret_statement(
  statement: Statement,
  state: ProgramState,
) -> Result(ProgramState, RuntimeError) {
  case statement {
    PrintStatement(line, expression) ->
      evaluate_in(expression, state.environment)
      |> result.map(fn(value) {
        ProgramState(
          outputs_rev: [value |> format.format, ..state.outputs_rev],
          environment: state.environment,
        )
      })
      |> result.map_error(runtime_error(line))
    ExpressionStatement(line, expression) ->
      evaluate_in(expression, state.environment)
      |> result.map(fn(_) { state })
      |> result.map_error(runtime_error(line))
    VarStatement(line, name, initializer) ->
      evaluate_in(initializer, state.environment)
      |> result.map(fn(value) {
        ProgramState(
          outputs_rev: state.outputs_rev,
          environment: state.environment |> dict.insert(name, value),
        )
      })
      |> result.map_error(runtime_error(line))
  }
}

fn runtime_error(line: Int) -> fn(String) -> RuntimeError {
  fn(message: String) { RuntimeError(message: message, line: line) }
}
