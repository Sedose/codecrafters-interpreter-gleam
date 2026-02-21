## In Gleam (this project is entirely usign Gleam)

- we use Result(a, Nil) instead of Option for most things including returning optional data.

- we have shadowing, so you don't have to do this token0, token1 business to not collide with token binding (variable (btw runtime constant)).

- Writing a recursive function would be much easier to follow than forcing it into a list.fold pattern.

- You can pattern match on prefixes, getting rid of this additional pending state you need to keep track of
pattern matching on strings prefixes would work really well here and would mean you don't have to build a list of graphemes.

- Appending to lists always copies them entirely, it's better to build the list in reverse and then reverse once right at the end before you return.

- Prefer pipeline style (`value |> transform |> consume`) over step-by-step temporary-variable flows like `result1 = func1(value)` then `result2 = func2(result1)`.

- Obey denesting: when a function gets nested `case`/branching, extract focused helper functions to keep the top-level flow flat and readable.

- After task completion, follow this pipeline only:
  1. Run `gleam format`.
  2. Resolve errors if any.
  3. Run `gleam check`.
  4. Resolve errors if any.
  5. Repeat steps 1-4 until clean.
  6. Run `codecrafters submit`.
  7. Explain what the error is or what needs to be implemented; explain only, do not implement yet.
  Do not run `gleam check` multiple times without code changes.

## Cool prompts to enhance a project

### evaluate all modules for high cohesion

Let the agent work till the result is smth like:

```
Module-by-module:

  1. High cohesion: src/main.gleam
     Single responsibility: CLI orchestration and exit-code routing.
  2. High cohesion: src/tokenizer.gleam
     Single responsibility: lexical scanning/tokenization.
  3. High cohesion: src/parser.gleam
     Single responsibility: parse tokens into AST / parse errors.
  4. High cohesion: src/tokenization_printer.gleam
     Single responsibility: tokenization/error output formatting + printing.
  5. High cohesion: src/parse_error_printer.gleam
     Single responsibility: parse error message formatting.
  6. High cohesion: src/ast_printer.gleam
     Single responsibility: AST rendering.
  7. High cohesion: src/util.gleam
     Single responsibility: character classification helpers.
  8. High cohesion: src/external_things.gleam
     Single responsibility: external runtime boundary (exit).
  9. High cohesion: src/data_def.gleam
     Single responsibility: shared domain/ADT definitions.
```

### Can `module_name` be simplified ?

