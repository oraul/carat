# Backlog: test/smoke_editor.rb

## test/smoke_editor.rb: intermittent snapshot mismatch under the check's parallel load

- Location: `test/smoke_editor.rb`, the PTY sessions that wait with `settle` for a fixed time before asserting on the drawn bytes (the tree check among them).
- Why it matters: one check run failed `smoke_editor.rb` (first exit 1, then exit 0 with differing output) while the same test passed alone, with the dev binary, under eight busy loops, and in the next full check at the same commit; a timing-dependent assertion can fail a merge for no change in behavior. The failing output was not kept, since the check's clone removes it, so the failing line is unknown.
- Fix outline: make `settle` wait until the output stops growing or a deadline passes, rather than a fixed time, and have `run_tests.sh` print `diff -a` so a binary-looking snapshot difference shows its lines.
- Category: code-quality
- Added: 2026-11-24

### the NO_COLOR bar case asserts only that name and type at test/smoke_editor.rb:409 (sprint-32 sweep quality, note 66)
- Location: test/smoke_editor.rb:409
- Why: the NO_COLOR bar case asserts only that name and type differ and the bold pattern, never that no color sequence (38; or 48;) is written, so it passes if NO_COLOR were ignored, and the comment at 393 (its sequences are the 256 colors' ones) reads as if colors were expected
- Fix: assert plain.name, plain.quiet, and plain.indicator hold no 38; or 48; and reword the comment
- Category: quality

### sequence_before walks back to any ESC and then to the at test/smoke_editor.rb:87 (sprint-32 sweep quality, note 67)
- Location: test/smoke_editor.rb:87
- Why: sequence_before walks back to any ESC and then to the next m, so a cursor move written between the SGR and the word (ESC[r;cH) yields a slice running past the move into later text
- Fix: walk back to the last ESC[ whose sequence ends in m before the word, or skip non-SGR sequences
- Category: quality
