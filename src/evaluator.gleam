import data_def.{
  type Expr, type LiteralValue, type UnaryOp, Binary, FalseLiteral, Grouping,
  Literal, NegateOp, NilLiteral, NotOp, NumberLiteral, StringLiteral,
  TrueLiteral, Unary, Variable,
}
import gleam/float
import gleam/string

pub fn evaluate(expression: Expr) -> Result(LiteralValue, String) {
  case expression {
    Literal(value) -> Ok(value)
    Grouping(inner) -> evaluate(inner)
    Variable(_) -> Error("Unsupported expression for this stage.")
    Unary(op, right) -> evaluate_unary(op, right)
    Binary(_, _, _) -> Error("Unsupported expression for this stage.")
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
