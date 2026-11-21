# Backlog: test/editor_grammar.rb

### test/editor_grammar.rb:47 untyped table values reach Cursor#move_to

- Quality advisory, typed table values and duplication (corrects the earlier note, which named editor_operators): the same move_to(Carat::Json.element(input[1], 0), Carat::Json.element(input[1], 1)) line, rewritten in 15 test files, still hands untyped table values to Cursor#move_to.
- Fix: convert with .to_i as the typed-table rule says (test/editor_registers.rb already does), ideally through one shared helper.
- Also: test/editor_registers.rb
- Category: code-quality
- Added: 2026-11-15
