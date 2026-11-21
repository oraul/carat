# Backlog: carat/adapters/indent_guides.rb

## IndentGuides keeps a magic stamp shift, a doubled guard, and a misleading helper name

- Where, at 6cb3c55: `carat/adapters/indent_guides.rb` line 62 (the settings stamp shifts by the unnamed 16_384 and folds in `@tabstop`, which `build_key` already puts in the geometry key), line 106 (`paint` checks `@code == 0` and `i >= @rows` although its only caller, `carat/adapters/frame_presenter.rb` line 785, passes -1 unless the row is guided and inside the buffer), line 132 (private `indent_of(line)` returns a display width while `Buffer#indent_of(row)` returns the whitespace string); `test/adapters_indent_guides.rb` line 150 (the glyph case `default` sets `indentguides = true`, which `state_for` already does). Quality advisories in `indent-guides`.
- Why it matters: the unnamed shift and the doubled tabstop make the stamp harder to check against `INDENT_CAP` and `SCOPE_SHIFT`; two guards for one condition can drift apart; one method name with two meanings misleads a reader of either file; the dead branch suggests the default case differs from the others.
- Fix outline: name the shift as a constant beside `INDENT_CAP` and `SCOPE_SHIFT` and drop `@tabstop` from the stamp; keep one guard, either dropping it from `paint` or setting `@guide_row` to the row whenever it is guided; rename the helper `indent_width`; drop the assignment and leave `default` with no branch.
- Also: carat/adapters/frame_presenter.rb, test/adapters_indent_guides.rb
- Category: editor
- Added: 2026-11-10
