import argv
import ast_printer
import data_def.{
  type Expr, type InterpretationResult, type LiteralValue, type Statement,
  type Token, type TokenWithLine, Completed, Failed, RuntimeError,
  TokenizationResult, TokenizationResultWithLines,
}
import evaluator
import external_things.{exit}
import gleam/int
import gleam/io
import gleam/list
import parse_error_printer.{format_error}
import parser.{parse, parse_program}
import simplifile.{describe_error}
import tokenization_printer.{print, print_errors}
import tokenizer.{tokenize, tokenize_with_lines}

const exit_code_success = 0

const exit_code_general_error = 1

const exit_code_language_error = 65

const exit_code_runtime_error = 70

const usage_message = "Usage: ./your_program.sh tokenize|parse|evaluate|run <filename>"

pub fn main() -> Nil {
  let exit_code = case argv.load().arguments {
    ["tokenize", filename] -> execute_with_file(filename, process_tokenize)
    ["parse", filename] -> execute_with_file(filename, process_parse)
    ["evaluate", filename] -> execute_with_file(filename, process_evaluate)
    ["run", filename] -> execute_with_file(filename, process_run)
    _ -> {
      io.println_error(usage_message)
      exit_code_general_error
    }
  }

  exit(exit_code)
}

fn execute_with_file(filename: String, process: fn(String) -> Int) -> Int {
  case simplifile.read(filename) {
    Ok(contents) -> process(contents)
    Error(err) -> {
      err
      |> describe_error
      |> io.println_error
      exit_code_general_error
    }
  }
}

fn process_tokenize(contents: String) -> Int {
  let tokenization_result = tokenize(contents)
  tokenization_result |> print

  case tokenization_result.errors {
    [] -> exit_code_success
    _ -> exit_code_language_error
  }
}

fn process_parse(contents: String) -> Int {
  case contents |> tokenize_and_parse {
    Ok(expression) -> {
      expression |> ast_printer.print
      exit_code_success
    }
    Error(exit_code) -> exit_code
  }
}

fn process_evaluate(contents: String) -> Int {
  case contents |> tokenize_and_parse {
    Ok(expression) -> expression |> evaluator.evaluate |> resolve_evaluation
    Error(exit_code) -> exit_code
  }
}

fn process_run(contents: String) -> Int {
  case contents |> tokenize_and_parse_program {
    Ok(statements) -> statements |> evaluator.interpret |> resolve_run_result
    Error(exit_code) -> exit_code
  }
}

fn tokenize_and_parse(contents: String) -> Result(Expr, Int) {
  case tokenize(contents) {
    TokenizationResult(tokens: tokens, errors: []) -> tokens |> parse_tokens
    TokenizationResult(tokens: _, errors: errors) -> {
      errors |> print_errors
      Error(exit_code_language_error)
    }
  }
}

fn tokenize_and_parse_program(contents: String) -> Result(List(Statement), Int) {
  case tokenize_with_lines(contents) {
    TokenizationResultWithLines(tokens: tokens, errors: []) ->
      tokens |> parse_program_tokens
    TokenizationResultWithLines(tokens: _, errors: errors) -> {
      errors |> print_errors
      Error(exit_code_language_error)
    }
  }
}

fn parse_tokens(tokens: List(Token)) -> Result(Expr, Int) {
  case parse(tokens) {
    Ok(expression) -> Ok(expression)
    Error(error) -> {
      error |> format_error |> io.println_error
      Error(exit_code_language_error)
    }
  }
}

fn parse_program_tokens(
  tokens: List(TokenWithLine),
) -> Result(List(Statement), Int) {
  case parse_program(tokens) {
    Ok(statements) -> Ok(statements)
    Error(error) -> {
      error |> format_error |> io.println_error
      Error(exit_code_language_error)
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

fn resolve_run_result(run_result: InterpretationResult) -> Int {
  case run_result {
    Completed(lines) -> {
      lines |> list.map(io.println)
      exit_code_success
    }
    Failed(outputs: outputs, error: RuntimeError(message: message, line: line)) -> {
      outputs |> list.map(io.println)
      io.println_error(message <> "\n\n[line " <> int.to_string(line) <> "]")
      exit_code_runtime_error
    }
  }
}
