import gleeunit/should
import tokenizer.{
  type Token, type TokenizationError, Eof, LeftBrace, LeftParen, Plus,
  RightBrace, RightParen, Semicolon, Star, UnrecognizedChar, Identifier, Number, Return, tokenize,
}

type TestCase {
  SuccessTestCase(name: String, input: String, expected_tokens: List(Token))
  WithErrorsTestCase(
    name: String,
    input: String,
    expected_tokens: List(Token),
    expected_errors: List(TokenizationError),
  )
}

fn get_test_cases() -> List(TestCase) {
  [
    SuccessTestCase(name: "empty string", input: "", expected_tokens: [Eof]),
    SuccessTestCase(name: "single left paren", input: "(", expected_tokens: [
      LeftParen,
      Eof,
    ]),
    SuccessTestCase(name: "single right paren", input: ")", expected_tokens: [
      RightParen,
      Eof,
    ]),
    SuccessTestCase(name: "single left brace", input: "{", expected_tokens: [
      LeftBrace,
      Eof,
    ]),
    SuccessTestCase(name: "single right brace", input: "}", expected_tokens: [
      RightBrace,
      Eof,
    ]),
    SuccessTestCase(name: "matching parens", input: "()", expected_tokens: [
      LeftParen,
      RightParen,
      Eof,
    ]),
    SuccessTestCase(name: "matching braces", input: "{}", expected_tokens: [
      LeftBrace,
      RightBrace,
      Eof,
    ]),
    SuccessTestCase(name: "mixed brackets", input: "({)}", expected_tokens: [
      LeftParen,
      LeftBrace,
      RightParen,
      RightBrace,
      Eof,
    ]),
    SuccessTestCase(name: "nested brackets", input: "{()}", expected_tokens: [
      LeftBrace,
      LeftParen,
      RightParen,
      RightBrace,
      Eof,
    ]),
    SuccessTestCase(name: "multiple pairs", input: "(){}()", expected_tokens: [
      LeftParen,
      RightParen,
      LeftBrace,
      RightBrace,
      LeftParen,
      RightParen,
      Eof,
    ]),
    SuccessTestCase(name: "ignores letters", input: "a(b)c", expected_tokens: [
      Identifier("a"),
      LeftParen,
      Identifier("b"),
      RightParen,
      Identifier("c"),
      Eof,
    ]),
    SuccessTestCase(name: "ignores numbers", input: "1(2)3", expected_tokens: [
      Number("1", 1.0),
      LeftParen,
      Number("2", 2.0),
      RightParen,
      Number("3", 3.0),
      Eof,
    ]),
    SuccessTestCase(
      name: "ignores whitespace",
      input: " ( ) { } ",
      expected_tokens: [LeftParen, RightParen, LeftBrace, RightBrace, Eof],
    ),
    SuccessTestCase(
      name: "ignores newlines and tabs",
      input: "(\n)\t{\r}",
      expected_tokens: [LeftParen, RightParen, LeftBrace, RightBrace, Eof],
    ),
    SuccessTestCase(
      name: "complex mixed content",
      input: "function() { return value; }",
      expected_tokens: [
        Identifier("function"),
        LeftParen,
        RightParen,
        LeftBrace,
        Return,
        Identifier("value"),
        Semicolon,
        RightBrace,
        Eof,
      ],
    ),
    SuccessTestCase(name: "plus", input: "+", expected_tokens: [Plus, Eof]),
    WithErrorsTestCase(
      name: "Unknown tokens",
      input: "{}🤡",
      expected_tokens: [LeftBrace, RightBrace, Eof],
      expected_errors: [UnrecognizedChar(line_number: 1, unexpected_char: "🤡")],
    ),
    WithErrorsTestCase(
      name: "Unknown tokens",
      input: "{}🤡\n{🍏}\n*🔥",
      expected_tokens: [LeftBrace, RightBrace, LeftBrace, RightBrace, Star, Eof],
      expected_errors: [
        UnrecognizedChar(line_number: 1, unexpected_char: "🤡"),
        UnrecognizedChar(line_number: 2, unexpected_char: "🍏"),
        UnrecognizedChar(line_number: 3, unexpected_char: "🔥"),
      ],
    ),
  ]
}

pub fn tokenize_test() {
  let test_cases = get_test_cases()
  run_test_cases(test_cases)
}

fn run_test_cases(test_cases: List(TestCase)) -> Nil {
  case test_cases {
    [] -> Nil
    [SuccessTestCase(_, input, expected_tokens), ..rest] -> {
      let tokenization_result = tokenize(input)
      let actual_tokens = tokenization_result.tokens
      should.equal(actual_tokens, expected_tokens)
      run_test_cases(rest)
    }
    [WithErrorsTestCase(_, input, expected_tokens, expected_errors), ..rest] -> {
      let tokenization_result = tokenize(input)
      let actual_tokens = tokenization_result.tokens
      let actual_errors = tokenization_result.errors
      should.equal(actual_tokens, expected_tokens)
      should.equal(actual_errors, expected_errors)
      run_test_cases(rest)
    }
  }
}
