# Backlog: carat/domain/status_slots.rb

## The status bar's branch slot has no writer

- Where: `carat/domain/status_slots.rb` (line 8 at `bars`) and the `BRANCH` path of `carat/adapters/status_bar.rb`. Quality advisory of `bars`; `lsp-diagnostics` writes the lsp slot and `diagnostics-display` the diagnostics counts.
- Why it matters: nothing in the code writes the branch, so this code is reachable only from tests until the git change fills it.
- Fix outline: the change that shows the git branch fills `branch`. If it is dropped from the queue, remove the slot and its path with their test rows.
- Also: carat/adapters/status_bar.rb
- Category: editor
- Added: 2026-11-07

## StatusSlots counts an error in a needless branch

- Where: `count_diagnostics` in `carat/domain/status_slots.rb` (line 65 at 38d8c47). Quality advisory at `diagnostics-display`, reported twice.
- Why it matters: `error?` is `severity == 1`, so both arms add one to `counts[severity]`; the branch reads as if errors were counted apart.
- Fix outline: drop the `if` and keep `counts[diagnostic.severity] += 1`.
- Category: editor
- Added: 2026-11-07

## A server's progress title is stored raw and copied per report

- Where: `carat/domain/status_slots.rb` line 60, fed from `carat/adapters/json_rpc_language_gateway.rb` line 1038, at 31919d9. Periodic security Low (3). Queue item `lsp-client-tidy`.
- Why it matters: a `$/progress` begin title up to the 8 MiB body limit is kept whole and joined with every later report's message before it is cut, so a hostile server costs a multi-megabyte copy per report, up to 64 per tick.
- Fix outline: store the title already cut to the progress limit, with a `test/adapters_language_gateway.rb` row for an oversized title.
- Also: carat/adapters/json_rpc_language_gateway.rb, test/adapters_language_gateway.rb
- Category: security
- Added: 2026-11-09

### StatusSlots#set_lsp reports a change on every empty-name call

- Location: carat/domain/status_slots.rb:47 (sweep, quality).
- Why: it stores :none for an empty name but compares the given state, so each call answers changed and asks for a redraw.
- Fix outline: normalize the state before the comparison.
- Category: editor
- Added: 2026-11-17

### StatusSlots lsp_label is no longer read by the bar
- Location: `carat/domain/status_slots.rb` (`lsp_label`, `label`), `test/adapters_language_gateway.rb:179`
- Why: the status bar draws the name, a dot, and `hint(state)` from `lsp_name` and `lsp_state`, so the record member and its state words are read only by the gateway tests and `set_lsp`'s change check.
- Fix: assert `lsp_state`, `hint`, and the progress percent in the gateway tests, then drop `lsp_label` and `label` from the record.
- Also: test/adapters_language_gateway.rb
- Category: editor
- Added: 2026-11-23

### lsp_label and StatusSlots.label are drawn nowhere since #321 (the at carat/domain/status_slots.rb:18 (sprint-30 sweep quality, note 32)

- Location: carat/domain/status_slots.rb:18
- Why: lsp_label and StatusSlots.label are drawn nowhere since #321 (the bar draws lsp_name, a dot, and StatusSlots.hint), yet set_lsp still builds a label string per call and the class comment (lines 10-12) still says it is the label the bar draws; only test/editor_lsp.rb and test/adapters_language_gateway.rb read it
- Fix: drop the lsp_label member and label, compare name, state, and percent in set_lsp, and have the tests print lsp_name and lsp_state, or keep label as a test-only formatter and correct the comment
- Also: test/editor_lsp.rb, test/adapters_language_gateway.rb
- Category: editor
- Added: 2026-11-23
