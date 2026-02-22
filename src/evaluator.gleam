import data_def.{
  type BinaryOp, type Expr, type InterpretationResult, type LiteralValue,
  type RuntimeError, type Statement, type UnaryOp, AddOp, Binary, Completed,
  DivideOp, EqualEqualOp, ExpressionStatement, Failed, FalseLiteral,
  GreaterEqualOp, GreaterOp, Grouping, LessEqualOp, LessOp, Literal, MultiplyOp,
  NegateOp, NilLiteral, NotEqualOp, NotOp, NumberLiteral, PrintStatement,
  RuntimeError, StringLiteral, SubtractOp, TrueLiteral, Unary, Variable,
}
import gleam/float
import gleam/list
import gleam/result
import gleam/string

pub fn interpret(statements: List(Statement)) -> InterpretationResult {
  interpret_statements(statements, [])
}

fn interpret_statements(
  statements: List(Statement),
  outputs_rev: List(String),
) -> InterpretationResult {
  case statements {
    [] -> Completed(outputs_rev |> list.reverse)
    [statement, ..rest] ->
      case interpret_statement(statement, outputs_rev) {
        Ok(next_outputs_rev) -> interpret_statements(rest, next_outputs_rev)
        Error(error) ->
          Failed(outputs: outputs_rev |> list.reverse, error: error)
      }
  }
}

fn interpret_statement(
  statement: Statement,
  outputs_rev: List(String),
) -> Result(List(String), RuntimeError) {
  case statement {
    PrintStatement(line, expression) ->
      evaluate(expression)
      |> result.map(fn(value) { [value |> format, ..outputs_rev] })
      |> result.map_error(runtime_error(line))
    ExpressionStatement(line, expression) ->
      evaluate(expression)
      |> result.map(fn(_) { outputs_rev })
      |> result.map_error(runtime_error(line))
  }
}

fn runtime_error(line: Int) -> fn(String) -> RuntimeError {
  fn(message: String) { RuntimeError(message: message, line: line) }
}

pub fn evaluate(expression: Expr) -> Result(LiteralValue, String) {
  case expression {
    Literal(value) -> Ok(value)
    Grouping(inner) -> evaluate(inner)
    Variable(_) -> Error("Unsupported expression for this stage.")
    Unary(op, right) -> evaluate_unary(op, right)
    Binary(op, left, right) -> evaluate_binary(op, left, right)
  }
}

fn evaluate_binary(
  op: BinaryOp,
  left: Expr,
  right: Expr,
) -> Result(LiteralValue, String) {
  case op {
    AddOp -> evaluate_add(left, right)
    SubtractOp ->
      evaluate_binary_numbers(left, right, fn(left_number, right_number) {
        NumberLiteral(left_number -. right_number)
      })
    MultiplyOp ->
      evaluate_binary_numbers(left, right, fn(left_number, right_number) {
        NumberLiteral(left_number *. right_number)
      })
    DivideOp ->
      evaluate_binary_numbers(left, right, fn(left_number, right_number) {
        NumberLiteral(left_number /. right_number)
      })
    GreaterOp ->
      evaluate_binary_numbers(left, right, fn(left_number, right_number) {
        bool_to_literal(left_number >. right_number)
      })
    GreaterEqualOp ->
      evaluate_binary_numbers(left, right, fn(left_number, right_number) {
        bool_to_literal(left_number >=. right_number)
      })
    LessOp ->
      evaluate_binary_numbers(left, right, fn(left_number, right_number) {
        bool_to_literal(left_number <. right_number)
      })
    LessEqualOp ->
      evaluate_binary_numbers(left, right, fn(left_number, right_number) {
        bool_to_literal(left_number <=. right_number)
      })
    EqualEqualOp -> evaluate_equality(left, right, True)
    NotEqualOp -> evaluate_equality(left, right, False)
  }
}

fn evaluate_add(left: Expr, right: Expr) -> Result(LiteralValue, String) {
  case evaluate(left), evaluate(right) {
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
  combine: fn(Float, Float) -> LiteralValue,
) -> Result(LiteralValue, String) {
  case evaluate(left), evaluate(right) {
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
  should_check_equal: Bool,
) -> Result(LiteralValue, String) {
  case evaluate(left), evaluate(right) {
    Ok(left_value), Ok(right_value) ->
      Ok(
        bool_to_literal(case should_check_equal {
          True -> left_value == right_value
          False -> left_value != right_value
        }),
      )
    Error(error), _ -> Error(error)
    _, Error(error) -> Error(error)
  }
}

fn bool_to_literal(value: Bool) -> LiteralValue {
  case value {
    True -> TrueLiteral
    False -> FalseLiteral
  }
}

fn evaluate_unary(op: UnaryOp, right: Expr) -> Result(LiteralValue, String) {
  case evaluate(right) {
    Ok(value) -> apply_unary(op, value)
    Error(error) -> Error(error)
  }
}

fn apply_unary(op: UnaryOp, value: LiteralValue) -> Result(LiteralValue, String) {
  case op {
    NotOp ->
      case is_truthy(value) {
        True -> Ok(FalseLiteral)
        False -> Ok(TrueLiteral)
      }

    NegateOp ->
      case value {
        NumberLiteral(number) -> Ok(NumberLiteral(0.0 -. number))
        _ -> Error("Operand must be a number.")
      }
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
