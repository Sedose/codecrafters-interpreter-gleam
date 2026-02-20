import data_def.{
  type Expr, type LiteralValue, Binary, FalseLiteral, Grouping, Literal,
  NilLiteral, NumberLiteral, StringLiteral, TrueLiteral, Unary,
}
import gleam/float

pub fn evaluate(expression: Expr) -> Result(LiteralValue, String) {
  case expression {
    Literal(value) -> Ok(value)
    Grouping(inner) -> evaluate(inner)
    Unary(_, _) -> Error("Unsupported expression for this stage.")
    Binary(_, _, _) -> Error("Unsupported expression for this stage.")
  }
}

pub fn format(value: LiteralValue) -> String {
  case value {
    TrueLiteral -> "true"
    FalseLiteral -> "false"
    NilLiteral -> "nil"
    NumberLiteral(number) -> float.to_string(number)
    StringLiteral(text) -> text
  }
}
