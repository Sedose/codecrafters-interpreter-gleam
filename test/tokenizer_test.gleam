import gleeunit/should
import gleam/io
import tokenizer.{type Token, Eof, LeftBrace, LeftParen, RightBrace, RightParen, tokenize}

type TestCase {
  TestCase(name: String, input: String, expected: List(Token))
}

fn get_test_cases() -> List(TestCase) {
  [
    TestCase(
      name: "empty string",
      input: "",
      expected: [Eof],
    ),
    TestCase(
      name: "single left paren",
      input: "(",
      expected: [LeftParen("("), Eof],
    ),
    TestCase(
      name: "single right paren",
      input: ")",
      expected: [RightParen(")"), Eof],
    ),
    TestCase(
      name: "single left brace",
      input: "{",
      expected: [LeftBrace("{"), Eof],
    ),
    TestCase(
      name: "single right brace",
      input: "}",
      expected: [RightBrace("}"), Eof],
    ),
    TestCase(
      name: "matching parens",
      input: "()",
      expected: [LeftParen("("), RightParen(")"), Eof],
    ),
    TestCase(
      name: "matching braces",
      input: "{}",
      expected: [LeftBrace("{"), RightBrace("}"), Eof],
    ),
    TestCase(
      name: "mixed brackets",
      input: "({)}",
      expected: [LeftParen("("), LeftBrace("{"), RightParen(")"), RightBrace("}"), Eof],
    ),
    TestCase(
      name: "nested brackets",
      input: "{()}",
      expected: [LeftBrace("{"), LeftParen("("), RightParen(")"), RightBrace("}"), Eof],
    ),
    TestCase(
      name: "multiple pairs",
      input: "(){}()",
      expected: [
        LeftParen("("), RightParen(")"),
        LeftBrace("{"), RightBrace("}"),
        LeftParen("("), RightParen(")"),
        Eof
      ],
    ),
    TestCase(
      name: "ignores letters",
      input: "a(b)c",
      expected: [LeftParen("("), RightParen(")"), Eof],
    ),
    TestCase(
      name: "ignores numbers",
      input: "1(2)3",
      expected: [LeftParen("("), RightParen(")"), Eof],
    ),
    TestCase(
      name: "ignores whitespace",
      input: " ( ) { } ",
      expected: [LeftParen("("), RightParen(")"), LeftBrace("{"), RightBrace("}"), Eof],
    ),
    TestCase(
      name: "ignores newlines and tabs",
      input: "(\n)\t{\r}",
      expected: [LeftParen("("), RightParen(")"), LeftBrace("{"), RightBrace("}"), Eof],
    ),
    TestCase(
      name: "ignores special characters",
      input: "@(#)$%^&*",
      expected: [LeftParen("("), RightParen(")"), Eof],
    ),
    TestCase(
      name: "complex mixed content",
      input: "function() { return value; }",
      expected: [LeftParen("("), RightParen(")"), LeftBrace("{"), RightBrace("}"), Eof],
    ),
  ]
}

// pub fn tokenize_test() {
//   // This should cause a test failure if the test runs
//   should.equal(1, 2)
  
//   io.println("Starting tokenizer tests...")
//   let test_cases = get_test_cases()
//   run_test_cases(test_cases)
//   io.println("All tokenizer tests completed!")
// }

pub fn tokenize_test() {
  // This should cause a test failure if the test runs
  should.equal(1, 2)  // This should FAIL
  
  io.println("Starting tokenizer tests...")
  let test_cases = get_test_cases()
  run_test_cases(test_cases)
  io.println("All tokenizer tests completed!")
}

fn run_test_cases(test_cases: List(TestCase)) -> Nil {
  case test_cases {
    [] -> Nil
    [TestCase(name, input, expected), ..rest] -> {
      io.println("✓ Testing: " <> name)
      let actual = tokenize(input)
      actual
      |> should.equal(expected)
      // If we reach here, the test passed
      run_test_cases(rest)
    }
  }
}

