# Backlog: carat/use_cases/docs/show_signature.rb

## The signature float's placement below the cursor is untested

- Where: `ShowSignature` in `carat/use_cases/docs/show_signature.rb` line 66 at c59a43d, which puts the float below the cursor (row 1) when the cursor's screen row is under 3; `test/adapters_signature.rb` has no row for it. Quality advisory in `parameter-info`.
- Why it matters: a regression in the below-the-cursor branch, the one taken on a window's first rows, would pass every test.
- Fix outline: add a row typing `(` on the window's first screen row and assert the bordered float drawn below the cursor.
- Also: test/adapters_signature.rb
- Category: editor
- Added: 2026-11-07
