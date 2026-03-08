import data_def.{
  type Expr, type LanguageError, type Statement, type Token, type TokenWithLine,
  type TokenizationResult, ParsingError, TokenizationErrors,
  TokenizationResult, TokenizationResultWithLines, exit_code_general_error,
}
import evaluator
import gleam/io
import gleam/result
import parser.{parse, parse_program}
import simplifile.{describe_error}
import tokenizer.{tokenize, tokenize_with_lines}

pub fn execute_with_file(filename: String, process: fn(String) -> Int) -> Int {
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

pub fn process_tokenize(contents: String) -> TokenizationResult {
  tokenize(contents)
}

pub fn process_parse(contents: String) -> Result(Expr, LanguageError) {
  contents |> tokenize_and_parse
}

pub fn process_evaluate(
  contents: String,
) -> Result(Result(data_def.LiteralValue, String), LanguageError) {
  contents |> tokenize_and_parse |> result.map(evaluator.evaluate)
}

pub fn process_run(
  contents: String,
) -> Result(data_def.InterpretationResult, LanguageError) {
  contents |> tokenize_and_parse_program |> result.map(evaluator.interpret)
}

fn tokenize_and_parse(contents: String) -> Result(Expr, LanguageError) {
  case tokenize(contents) {
    TokenizationResult(tokens: tokens, errors: []) -> tokens |> parse_tokens
    TokenizationResult(tokens: _, errors: errors) ->
      Error(TokenizationErrors(errors))
  }
}

fn tokenize_and_parse_program(
  contents: String,
) -> Result(List(Statement), LanguageError) {
  case tokenize_with_lines(contents) {
    TokenizationResultWithLines(tokens: tokens, errors: []) ->
      tokens |> parse_program_tokens
    TokenizationResultWithLines(tokens: _, errors: errors) ->
      Error(TokenizationErrors(errors))
  }
}

fn parse_tokens(tokens: List(Token)) -> Result(Expr, LanguageError) {
  case parse(tokens) {
    Ok(expression) -> Ok(expression)
    Error(error) -> Error(ParsingError(error))
  }
}

fn parse_program_tokens(
  tokens: List(TokenWithLine),
) -> Result(List(Statement), LanguageError) {
  case parse_program(tokens) {
    Ok(statements) -> Ok(statements)
    Error(error) -> Error(ParsingError(error))
  }
}
