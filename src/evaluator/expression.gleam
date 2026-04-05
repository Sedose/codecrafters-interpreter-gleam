import data_def.{
  type BinaryOp, type Expr, type LiteralValue, type UnaryOp, AddOp, Assignment,
  Binary, DivideOp, EqualEqualOp, FalseLiteral, GreaterEqualOp, GreaterOp,
  Grouping, LessEqualOp, LessOp, Literal, MultiplyOp, NegateOp, NilLiteral,
  NotEqualOp, NotOp, NumberLiteral, StringLiteral, SubtractOp, TrueLiteral,
  Unary, Variable,
}
import gleam/dict
import gleam/result

pub type Environment =
  dict.Dict(String, LiteralValue)

pub fn empty_environment() -> Environment {
  dict.new()
}

pub fn evaluate(expression: Expr) -> Result(LiteralValue, String) {
  evaluate_in(expression, empty_environment())
  |> result.map(fn(pair) {
    let #(value, _) = pair
    value
  })
}

pub fn evaluate_in(
  expression: Expr,
  environment: Environment,
) -> Result(#(LiteralValue, Environment), String) {
  case expression {
    Literal(value) -> Ok(#(value, environment))
    Grouping(inner) -> evaluate_in(inner, environment)
    Variable(name) -> lookup_variable(name, environment) |> with_environment(environment)
    Assignment(name, value) -> evaluate_assignment(name, value, environment)
    Unary(op, right) -> evaluate_unary(op, right, environment)
    Binary(op, left, right) -> evaluate_binary(op, left, right, environment)
  }
}

fn lookup_variable(
  name: String,
  environment: Environment,
) -> Result(LiteralValue, String) {
  case environment |> dict.get(name) {
    Ok(value) -> Ok(value)
    Error(_) -> Error("Undefined variable '" <> name <> "'.")
  }
}

fn with_environment(
  evaluation_result: Result(LiteralValue, String),
  environment: Environment,
) -> Result(#(LiteralValue, Environment), String) {
  evaluation_result |> result.map(fn(value) { #(value, environment) })
}

fn evaluate_assignment(
  name: String,
  value: Expr,
  environment: Environment,
) -> Result(#(LiteralValue, Environment), String) {
  evaluate_in(value, environment)
  |> result.try(fn(pair) {
    let #(value, environment) = pair
    assign_variable(name, value, environment)
  })
}

fn assign_variable(
  name: String,
  value: LiteralValue,
  environment: Environment,
) -> Result(#(LiteralValue, Environment), String) {
  case environment |> dict.get(name) {
    Ok(_) -> Ok(#(value, environment |> dict.insert(name, value)))
    Error(_) -> Error("Undefined variable '" <> name <> "'.")
  }
}

fn evaluate_binary(
  op: BinaryOp,
  left: Expr,
  right: Expr,
  environment: Environment,
) -> Result(#(LiteralValue, Environment), String) {
  evaluate_in(left, environment)
  |> result.try(fn(left_pair) {
    let #(left_value, environment) = left_pair
    evaluate_in(right, environment)
    |> result.try(fn(right_pair) {
      let #(right_value, environment) = right_pair
      apply_binary(op, left_value, right_value)
      |> with_environment(environment)
    })
  })
}

fn apply_binary(
  op: BinaryOp,
  left: LiteralValue,
  right: LiteralValue,
) -> Result(LiteralValue, String) {
  case op {
    AddOp -> apply_add(left, right)
    SubtractOp ->
      apply_binary_numbers(left, right, fn(left_number, right_number) {
        NumberLiteral(left_number -. right_number)
      })
    MultiplyOp ->
      apply_binary_numbers(left, right, fn(left_number, right_number) {
        NumberLiteral(left_number *. right_number)
      })
    DivideOp ->
      apply_binary_numbers(left, right, fn(left_number, right_number) {
        NumberLiteral(left_number /. right_number)
      })
    GreaterOp ->
      apply_binary_numbers(left, right, fn(left_number, right_number) {
        bool_to_literal(left_number >. right_number)
      })
    GreaterEqualOp ->
      apply_binary_numbers(left, right, fn(left_number, right_number) {
        bool_to_literal(left_number >=. right_number)
      })
    LessOp ->
      apply_binary_numbers(left, right, fn(left_number, right_number) {
        bool_to_literal(left_number <. right_number)
      })
    LessEqualOp ->
      apply_binary_numbers(left, right, fn(left_number, right_number) {
        bool_to_literal(left_number <=. right_number)
      })
    EqualEqualOp -> Ok(bool_to_literal(left == right))
    NotEqualOp -> Ok(bool_to_literal(left != right))
  }
}

fn apply_add(
  left: LiteralValue,
  right: LiteralValue,
) -> Result(LiteralValue, String) {
  case left, right {
    NumberLiteral(left_number), NumberLiteral(right_number) ->
      Ok(NumberLiteral(left_number +. right_number))
    StringLiteral(left_text), StringLiteral(right_text) ->
      Ok(StringLiteral(left_text <> right_text))
    _, _ -> Error("Operands must be two numbers or two strings.")
  }
}

fn apply_binary_numbers(
  left: LiteralValue,
  right: LiteralValue,
  combine: fn(Float, Float) -> LiteralValue,
) -> Result(LiteralValue, String) {
  case left, right {
    NumberLiteral(left_number), NumberLiteral(right_number) ->
      Ok(combine(left_number, right_number))
    _, _ -> Error("Operands must be numbers.")
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
) -> Result(#(LiteralValue, Environment), String) {
  evaluate_in(right, environment)
  |> result.try(fn(pair) {
    let #(value, environment) = pair
    apply_unary(op, value)
    |> with_environment(environment)
  })
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
