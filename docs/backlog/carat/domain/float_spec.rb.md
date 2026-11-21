# Backlog: carat/domain/float_spec.rb

## offset_refusal reassigns bad and compares abs (float-placement, quality advisory)

- Where: `carat/domain/float_spec.rb:57`, `offset_refusal`.
- Why it matters: simplicity: it picks the bad value by reassigning bad and compares row.abs, which is clever and overflows at the minimum integer.
- Fix outline: check each bound directly (row < -OFFSET_MAX or row > OFFSET_MAX, then col) and return the message for the first out of range.
- Category: editor
- Added: 2026-11-14

### FloatSpec writes its offset bound test twice
- Location: carat/domain/float_spec.rb:61
- Why: duplication: the bound test 'x >= -OFFSET_MAX && x <= OFFSET_MAX' is written twice (lines 61-62), where the design names one outside?(value) helper.
- Fix: add the class predicate outside?(value) and call it for row and bad.
- Category: editor
- Added: 2026-11-17
