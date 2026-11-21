# Backlog: test/editor_case_operators.rb

### Case operator test header comment runs past the wrap width
- Location: test/editor_case_operators.rb:12
- Why: the extended header comment runs to 79 columns, past the wrap width of the comment around it, the same kind of point the operator_handler.rb rewrap closed.
- Fix: rewrap the header comment.
- Category: code-quality
- Added: 2026-11-20

### test/editor_case_operators.rb:151: passes untyped table values (input[0], input[2], Carat::Json.element(input[1], n)) to (sprint-22 sweep quality)

- Location: `test/editor_case_operators.rb:151`
- Why: passes untyped table values (input[0], input[2], Carat::Json.element(input[1], n)) to the harness unconverted, against the typed table values rule, copied from test/editor_operators.rb:145-147
- Fix: .to_s on the strings and .to_i on the elements (or the ints helper) in both files
- Also: test/editor_operators.rb
- Category: code-quality
- Added: 2026-11-20
