import data_def.{
  type BinaryOp, type Expr, type LiteralValue, type UnaryOp, AddOp, Binary,
  DivideOp, EqualEqualOp, FalseLiteral, GreaterEqualOp, GreaterOp, Grouping,
  LessEqualOp, LessOp, Literal, MultiplyOp, NegateOp, NilLiteral, NotEqualOp,
  NotOp, NumberLiteral, StringLiteral, SubtractOp, TrueLiteral, Unary, Variable,
}
import gleam/dict

pub type Environment =
  dict.Dict(String, LiteralValue)

pub fn empty_environment() -> Environment {
  dict.new()
}

pub fn evaluate(expression: Expr) -> Result(LiteralValue, String) {
  evaluate_in(expression, empty_environment())
}

pub fn evaluate_in(
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
