import ast_printer
import data_def.{
  type InterpretationResult, type LanguageError, type LiteralValue,
  type TokenizationResult, Completed, Failed, ParsingError, RuntimeError,
  TokenizationErrors,
}
import evaluator
import gleam/int
import gleam/io
import gleam/list
import parse_error_printer.{format_error}
import tokenization_printer

pub const exit_code_success = 0

pub const exit_code_language_error = 65

pub const exit_code_runtime_error = 70

pub fn resolve_tokenize_result(result: TokenizationResult) -> Int {
  result |> tokenization_printer.print

  case result.errors {
    [] -> exit_code_success
    _ -> exit_code_language_error
  }
}

pub fn resolve_parse_result(result: Result(data_def.Expr, LanguageError)) -> Int {
  case result {
    Ok(expression) -> {
      expression |> ast_printer.print
      exit_code_success
    }
    Error(error) -> resolve_language_error(error)
  }
}

pub fn resolve_evaluation_result(
  result: Result(Result(LiteralValue, String), LanguageError),
) -> Int {
  case result {
    Ok(evaluation_result) -> resolve_evaluation(evaluation_result)
    Error(error) -> resolve_language_error(error)
  }
}

pub fn resolve_run_result(
  result: Result(InterpretationResult, LanguageError),
) -> Int {
  case result {
    Ok(run_result) -> resolve_interpretation_result(run_result)
    Error(error) -> resolve_language_error(error)
  }
}

fn resolve_language_error(error: LanguageError) -> Int {
  case error {
    TokenizationErrors(errors) -> {
      errors |> tokenization_printer.print_errors
      exit_code_language_error
    }
    ParsingError(error) -> {
      error |> format_error |> io.println_error
      exit_code_language_error
    }
  }
}

fn resolve_evaluation(evaluation_result: Result(LiteralValue, String)) -> Int {
  case evaluation_result {
    Ok(value) -> {
      value |> evaluator.format |> io.println
      exit_code_success
    }
    Error(message) -> {
      io.println_error(message <> "\n\n[line 1]")
      exit_code_runtime_error
    }
  }
}

fn resolve_interpretation_result(run_result: InterpretationResult) -> Int {
  case run_result {
    Completed(lines) -> {
      lines |> list.each(io.println)
      exit_code_success
    }
    Failed(outputs: outputs, error: RuntimeError(message: message, line: line)) -> {
      outputs |> list.each(io.println)
      io.println_error(message <> "\n\n[line " <> int.to_string(line) <> "]")
      exit_code_runtime_error
    }
  }
}
