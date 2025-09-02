import data_def.{
  type Expr, FalseLiteral, Grouping, Literal, NilLiteral, NumberLiteral,
  StringLiteral, TrueLiteral, Unary, type UnaryOp, NotOp, NegateOp,
  Binary, type BinaryOp, MultiplyOp, DivideOp,
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
    Unary(op, right) ->
      "(" <> format_unary_op(op) <> " " <> format(right) <> ")"
    Binary(op, left, right) ->
      "(" <> format_binary_op(op) <> " " <> format(left) <> " " <> format(right) <> ")"
  }
}

fn format_unary_op(op: UnaryOp) -> String {
  case op {
    NotOp -> "!"
    NegateOp -> "-"
  }
}

fn format_binary_op(op: BinaryOp) -> String {
  case op {
    MultiplyOp -> "*"
    DivideOp -> "/"
  }
}
