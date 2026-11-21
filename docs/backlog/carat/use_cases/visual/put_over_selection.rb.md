# Backlog: carat/use_cases/visual/put_over_selection.rb

## Put and operator advisories

- Where: `PutOverSelection#repeated` in `carat/use_cases/visual/put_over_selection.rb` line 124 copies the loop of `Operators.put` (`carat/domain/operators.rb` lines 42 to 47); `carat/use_cases/actions/edit_handler.rb` line 50 makes `put_before` the catch-all `else`; `carat/domain/operators.rb` line 4 requires `registers` and `selection`, using neither, and gets `Block` only through them; at 3895e21. Periodic quality. Queue item `editing-counts`.
- Why it matters: two copies of one loop, an unlisted variant silently putting before the cursor, and requires that hide what the file names.
- Fix outline: one repeated-lines function used by both; name `when :put_before` with no catch-all; require `register_entry` and `block`.
- Also: carat/domain/operators.rb, carat/use_cases/actions/edit_handler.rb
- Category: editor
- Added: 2026-11-09

## Visual operations compute what their selection kind never uses

- Where: `carat/use_cases/visual/put_over_selection.rb:38` (block, top column, and range for every kind); `carat/use_cases/visual/recase_selection.rb:23` (`Selection#span` rebuilds the block per row). Periodic quality at 9a92265.
- Why it matters: line scans per row of a large selection.
- Fix outline: compute each only for its kind, the block once per call. Queue item: backlog batches (dead code).
- Also: carat/use_cases/visual/recase_selection.rb
- Category: editor
- Added: 2026-11-10

### PutOverSelection repeats Operators.put's count loop

- Location: carat/use_cases/visual/put_over_selection.rb:124, carat/domain/operators.rb:42 (sweep, quality).
- Why: repeated copies the linewise count loop.
- Fix outline: one Operators.repeated(lines, count).
- Also: carat/domain/operators.rb
- Category: editor
- Added: 2026-11-17

### carat/use_cases/visual/put_over_selection.rb:124: repeated(lines, count) repeats the count loop Operators.put already runs (sprint-22 sweep quality)

- Location: `carat/use_cases/visual/put_over_selection.rb:124`
- Why: repeated(lines, count) repeats the count loop Operators.put already runs for linewise entries (carat/domain/operators.rb:42-47)
- Fix: one Operators helper for the repeated lines, used by both
- Also: carat/domain/operators.rb
- Category: editor
- Added: 2026-11-20
