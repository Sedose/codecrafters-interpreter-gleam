import gleeunit/should
import tokenizer.{
  type Token, Eof, LeftBrace, LeftParen, Plus, RightBrace, RightParen, tokenize,
}

type TestCase {
  TestCase(name: String, input: String, expected: List(Token))
}

fn get_test_cases() -> List(TestCase) {
  [
    TestCase(name: "empty string", input: "", expected: [Eof]),
    TestCase(name: "single left paren", input: "(", expected: [LeftParen, Eof]),
    TestCase(name: "single right paren", input: ")", expected: [RightParen, Eof]),
    TestCase(name: "single left brace", input: "{", expected: [LeftBrace, Eof]),
    TestCase(name: "single right brace", input: "}", expected: [RightBrace, Eof]),
    TestCase(name: "matching parens", input: "()", expected: [
      LeftParen,
      RightParen,
      Eof,
    ]),
    TestCase(name: "matching braces", input: "{}", expected: [
      LeftBrace,
      RightBrace,
      Eof,
    ]),
    TestCase(name: "mixed brackets", input: "({)}", expected: [
      LeftParen,
      LeftBrace,
      RightParen,
      RightBrace,
      Eof,
    ]),
    TestCase(name: "nested brackets", input: "{()}", expected: [
      LeftBrace,
      LeftParen,
      RightParen,
      RightBrace,
      Eof,
    ]),
    TestCase(name: "multiple pairs", input: "(){}()", expected: [
      LeftParen,
      RightParen,
      LeftBrace,
      RightBrace,
      LeftParen,
      RightParen,
      Eof,
    ]),
    TestCase(name: "ignores letters", input: "a(b)c", expected: [
      LeftParen,
      RightParen,
      Eof,
    ]),
    TestCase(name: "ignores numbers", input: "1(2)3", expected: [
      LeftParen,
      RightParen,
      Eof,
    ]),
    TestCase(name: "ignores whitespace", input: " ( ) { } ", expected: [
      LeftParen,
      RightParen,
      LeftBrace,
      RightBrace,
      Eof,
    ]),
    TestCase(name: "ignores newlines and tabs", input: "(\n)\t{\r}", expected: [
      LeftParen,
      RightParen,
      LeftBrace,
      RightBrace,
      Eof,
    ]),
    TestCase(name: "ignores special characters", input: "@(#)$%^&*", expected: [
      LeftParen,
      RightParen,
      Eof,
    ]),
    TestCase(
      name: "complex mixed content",
      input: "function() { return value; }",
      expected: [LeftParen, RightParen, LeftBrace, RightBrace, Eof],
    ),
    TestCase(name: "plus", input: "+", expected: [Plus, Eof]),
  ]
}

pub fn tokenize_test() {
  let test_cases = get_test_cases()
  run_test_cases(test_cases)
}

fn run_test_cases(test_cases: List(TestCase)) -> Nil {
  case test_cases {
    [] -> Nil
    [TestCase(_name, input, expected), ..rest] -> {
      let actual = tokenize(input)
      should.equal(actual, expected)
      run_test_cases(rest)
    }
  }
}
