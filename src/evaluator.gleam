import data_def.{
  type BinaryOp, type Expr, type LiteralValue, type Statement, type UnaryOp,
  AddOp, Binary, DivideOp, EqualEqualOp, ExpressionStatement, FalseLiteral,
  GreaterEqualOp, GreaterOp, Grouping, LessEqualOp, LessOp, Literal, MultiplyOp,
  NegateOp, NilLiteral, NotEqualOp, NotOp, NumberLiteral, PrintStatement,
  StringLiteral, SubtractOp, TrueLiteral, Unary, Variable,
}
import gleam/float
import gleam/list
import gleam/string

pub fn interpret(statements: List(Statement)) -> Result(List(String), String) {
  interpret_statements(statements, [])
}

fn interpret_statements(
  statements: List(Statement),
  outputs_rev: List(String),
) -> Result(List(String), String) {
  case statements {
    [] -> Ok(outputs_rev |> list.reverse)
    [PrintStatement(expression), ..rest] ->
      case evaluate(expression) {
        Ok(value) ->
          interpret_statements(rest, [value |> format, ..outputs_rev])
        Error(error) -> Error(error)
      }
    [ExpressionStatement(expression), ..rest] ->
      case evaluate(expression) {
        Ok(_) -> interpret_statements(rest, outputs_rev)
        Error(error) -> Error(error)
      }
  }
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
  case evaluate(left), evaluate(right), op {
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)), AddOp ->
      Ok(NumberLiteral(left_number +. right_number))
    Ok(StringLiteral(left_text)), Ok(StringLiteral(right_text)), AddOp ->
      Ok(StringLiteral(left_text <> right_text))
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)), SubtractOp ->
      Ok(NumberLiteral(left_number -. right_number))
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)), MultiplyOp ->
      Ok(NumberLiteral(left_number *. right_number))
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)), DivideOp ->
      Ok(NumberLiteral(left_number /. right_number))
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)), GreaterOp ->
      Ok(bool_to_literal(left_number >. right_number))
    Ok(NumberLiteral(left_number)),
      Ok(NumberLiteral(right_number)),
      GreaterEqualOp
    -> Ok(bool_to_literal(left_number >=. right_number))
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)), LessOp ->
      Ok(bool_to_literal(left_number <. right_number))
    Ok(NumberLiteral(left_number)), Ok(NumberLiteral(right_number)), LessEqualOp
    -> Ok(bool_to_literal(left_number <=. right_number))
    Ok(left_value), Ok(right_value), EqualEqualOp ->
      Ok(bool_to_literal(left_value == right_value))
    Ok(left_value), Ok(right_value), NotEqualOp ->
      Ok(bool_to_literal(left_value != right_value))
    Error(error), _, _ -> Error(error)
    _, Error(error), _ -> Error(error)
    _, _, _ -> Error("Operand must be a number.")
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
