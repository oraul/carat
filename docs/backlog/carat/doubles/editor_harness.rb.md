# Backlog: carat/doubles/editor_harness.rb

## Test helpers return tuples and misname table rows

- Where: `windows` in `carat/doubles/editor_harness.rb` line 189 returns seven-field arrays that 13 test call sites index by position (`test/editor_cmdline.rb` line 194, `test/editor_leader.rb` line 57); the table blocks of `test/plugins_finder_matcher.rb` lines 39 and 51 name their parameter `row` though `Testing#table` yields its input. Periodic quality at 2f54bb5. Queued in the bench and test hygiene batch.
- Why it matters: positional indexes break the rule that a helper returning several values returns an object with typed readers, and the wrong name misleads the reader.
- Fix outline: a small `Data` value with named readers read by name in the tests; rename the parameter `input`.
- Also: test/editor_cmdline.rb, test/editor_leader.rb, test/plugins_finder_matcher.rb
- Category: editor
- Added: 2026-11-10

### EditorHarness#windows returns tuples

- Location: carat/doubles/editor_harness.rb:190, 13 call sites such as test/editor_leader.rb:57 and test/editor_tabs.rb:247 (sprint-4 sweep, quality).
- Why: a seven-element array indexed by position, against the typed-readers rule.
- Fix: a small Data value with named readers.
- Also: test/editor_leader.rb, test/editor_tabs.rb
- Category: editor
- Added: 2026-11-14

### redraw is a public twin of the private render with at carat/doubles/editor_harness.rb:91 (sprint-32 sweep quality, note 87)
- Location: carat/doubles/editor_harness.rb:91
- Why: redraw is a public twin of the private render with the same body, two names for one frame
- Fix: make render public under one name (redraw) and call it from type, raw, wait, and resize
- Category: quality
