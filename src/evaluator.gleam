import data_def.{
  type BinaryOp, type Expr, type InterpretationResult, type LiteralValue,
  type RuntimeError, type Statement, type UnaryOp, AddOp, Binary, Completed,
  DivideOp, EqualEqualOp, ExpressionStatement, Failed, FalseLiteral,
  GreaterEqualOp, GreaterOp, Grouping, LessEqualOp, LessOp, Literal, MultiplyOp,
  NegateOp, NilLiteral, NotEqualOp, NotOp, NumberLiteral, PrintStatement,
  RuntimeError, StringLiteral, SubtractOp, TrueLiteral, Unary, VarStatement,
  Variable,
}
import gleam/dict
import gleam/float
import gleam/list
import gleam/result
import gleam/string

type Environment =
  dict.Dict(String, LiteralValue)

type ProgramState {
  ProgramState(outputs_rev: List(String), environment: Environment)
}

pub fn interpret(statements: List(Statement)) -> InterpretationResult {
  interpret_statements(
    statements,
    ProgramState(outputs_rev: [], environment: dict.new()),
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
          outputs_rev: [value |> format, ..state.outputs_rev],
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

pub fn evaluate(expression: Expr) -> Result(LiteralValue, String) {
  evaluate_in(expression, dict.new())
}

fn evaluate_in(
  expression: Expr,
  environment: Environment,
) -> Result(LiteralValue, String) {
  case expression {
    Literal(value) -> Ok(value)
    Grouping(inner) -> evaluate_in(inner, environment)
    Variable(name) ->
      case environment |> dict.get(name) {
        Ok(value) -> Ok(value)
        Error(_) -> Error("Undefined variable '" <> name <> "'.")
      }
    Unary(op, right) -> evaluate_unary(op, right, environment)
    Binary(op, left, right) -> evaluate_binary(op, left, right, environment)
  }
}

fn evaluate_binary(
  op: BinaryOp,
  left: Expr,
  right: Expr,
  environment: Environment,
) -> Result(LiteralValue, String) {
  case op {
    AddOp -> evaluate_add(left, right, environment)
    SubtractOp ->
      evaluate_binary_numbers(
        left,
        right,
        environment,
        fn(left_number, right_number) {
          NumberLiteral(left_number -. right_number)
        },
      )
    MultiplyOp ->
      evaluate_binary_numbers(
        left,
        right,
        environment,
        fn(left_number, right_number) {
          NumberLiteral(left_number *. right_number)
        },
      )
    DivideOp ->
      evaluate_binary_numbers(
        left,
        right,
        environment,
        fn(left_number, right_number) {
          NumberLiteral(left_number /. right_number)
        },
      )
    GreaterOp ->
      evaluate_binary_numbers(
        left,
        right,
        environment,
        fn(left_number, right_number) {
          bool_to_literal(left_number >. right_number)
        },
      )
    GreaterEqualOp ->
      evaluate_binary_numbers(
        left,
        right,
        environment,
        fn(left_number, right_number) {
          bool_to_literal(left_number >=. right_number)
        },
      )
    LessOp ->
      evaluate_binary_numbers(
        left,
        right,
        environment,
        fn(left_number, right_number) {
          bool_to_literal(left_number <. right_number)
        },
      )
    LessEqualOp ->
      evaluate_binary_numbers(
        left,
        right,
        environment,
        fn(left_number, right_number) {
          bool_to_literal(left_number <=. right_number)
        },
      )
    EqualEqualOp -> evaluate_equality(left, right, environment, True)
    NotEqualOp -> evaluate_equality(left, right, environment, False)
  }
}

fn evaluate_add(
  left: Expr,
  right: Expr,
  environment: Environment,
) -> Result(LiteralValue, String) {
  case evaluate_in(left, environment), evaluate_in(right, environment) {
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)) ->
      Ok(NumberLiteral(left_number +. right_number))
    Ok(StringLiteral(left_text)), Ok(StringLiteral(right_text)) ->
      Ok(StringLiteral(left_text <> right_text))
    Error(error), _ -> Error(error)
    _, Error(error) -> Error(error)
    _, _ -> Error("Operands must be two numbers or two strings.")
  }
}

fn evaluate_binary_numbers(
  left: Expr,
  right: Expr,
  environment: Environment,
  combine: fn(Float, Float) -> LiteralValue,
) -> Result(LiteralValue, String) {
  case evaluate_in(left, environment), evaluate_in(right, environment) {
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)) ->
      Ok(combine(left_number, right_number))
    Error(error), _ -> Error(error)
    _, Error(error) -> Error(error)
    _, _ -> Error("Operands must be numbers.")
  }
}

fn evaluate_equality(
  left: Expr,
  right: Expr,
  environment: Environment,
  should_check_equal: Bool,
) -> Result(LiteralValue, String) {
  case
    evaluate_in(left, environment),
    evaluate_in(right, environment),
    should_check_equal
  {
    Ok(left_value), Ok(right_value), True ->
      Ok(bool_to_literal(left_value == right_value))
    Ok(left_value), Ok(right_value), False ->
      Ok(bool_to_literal(left_value != right_value))
    Error(error), _, _ -> Error(error)
    _, Error(error), _ -> Error(error)
  }
}

fn bool_to_literal(value: Bool) -> LiteralValue {
  case value {
    True -> TrueLiteral
    False -> FalseLiteral
  }
}

fn evaluate_unary(
  op: UnaryOp,
  right: Expr,
  environment: Environment,
) -> Result(LiteralValue, String) {
  case evaluate_in(right, environment) {
    Ok(value) -> apply_unary(op, value)
    Error(error) -> Error(error)
  }
}

fn apply_unary(op: UnaryOp, value: LiteralValue) -> Result(LiteralValue, String) {
  case op, value {
    NotOp, _ -> Ok(bool_to_literal(!is_truthy(value)))
    NegateOp, NumberLiteral(number) -> Ok(NumberLiteral(0.0 -. number))
    NegateOp, _ -> Error("Operand must be a number.")
  }
}

fn is_truthy(value: LiteralValue) -> Bool {
  case value {
    FalseLiteral -> False
    NilLiteral -> False
    _ -> True
  }
}

pub fn format(value: LiteralValue) -> String {
  case value {
    TrueLiteral -> "true"
    FalseLiteral -> "false"
    NilLiteral -> "nil"
    NumberLiteral(number) -> format_number(number)
    StringLiteral(text) -> text
  }
}

fn format_number(number: Float) -> String {
  let formatted = number |> float.to_string

  case formatted |> string.ends_with(".0") {
    True -> string.drop_end(formatted, 2)
    False -> formatted
  }
}
