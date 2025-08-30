import ast.{
  type Expr, FalseLiteral, Literal, NilLiteral, NumberLiteral, StringLiteral,
  TrueLiteral,
}
import gleam/float
import gleam/io

pub fn print(expr: Expr) -> Nil {
  let output = case expr {
    Literal(value) ->
      case value {
        TrueLiteral -> "true"
        FalseLiteral -> "false"
        NilLiteral -> "nil"
        NumberLiteral(n) -> float.to_string(n)
        StringLiteral(s) -> s
      }
  }

  io.println(output)
}
