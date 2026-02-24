import data_def.{
  type LiteralValue, FalseLiteral, NilLiteral, NumberLiteral, StringLiteral,
  TrueLiteral,
}
import gleam/float
import gleam/string

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
