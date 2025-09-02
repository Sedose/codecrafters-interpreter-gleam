import data_def.{
  type Expr, FalseLiteral, Grouping, Literal, NilLiteral, NumberLiteral,
  StringLiteral, TrueLiteral,
}
import gleam/float
import gleam/io

pub fn print(expr: Expr) -> Nil {
  io.println(format(expr))
}

fn format(expr: Expr) -> String {
  case expr {
    Literal(value) ->
      case value {
        TrueLiteral -> "true"
        FalseLiteral -> "false"
        NilLiteral -> "nil"
        NumberLiteral(n) -> float.to_string(n)
        StringLiteral(s) -> s
      }
    Grouping(inner) -> "(group " <> format(inner) <> ")"
  }
}
