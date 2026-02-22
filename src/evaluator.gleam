import data_def.{
  type Expr, type LiteralValue, Binary, FalseLiteral, Grouping, Literal,
  NilLiteral, NumberLiteral, StringLiteral, TrueLiteral, Unary, Variable,
}
import gleam/float
import gleam/string

pub fn evaluate(expression: Expr) -> Result(LiteralValue, String) {
  case expression {
    Literal(value) -> Ok(value)
    Grouping(inner) -> evaluate(inner)
    Variable(_) -> Error("Unsupported expression for this stage.")
    Unary(_, _) -> Error("Unsupported expression for this stage.")
    Binary(_, _, _) -> Error("Unsupported expression for this stage.")
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
