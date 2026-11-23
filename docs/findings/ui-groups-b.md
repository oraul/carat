### StatusSlots lsp_label is no longer read by the bar
- Location: `carat/domain/status_slots.rb` (`lsp_label`, `label`), `test/adapters_language_gateway.rb:179`
- Why: the status bar draws the name, a dot, and `hint(state)` from `lsp_name` and `lsp_state`, so the record member and its state words are read only by the gateway tests and `set_lsp`'s change check.
- Fix: assert `lsp_state`, `hint`, and the progress percent in the gateway tests, then drop `lsp_label` and `label` from the record.
### Server states differ only by the dot's color
- Location: `carat/adapters/status_bar.rb` (`paint_lsp`, `lsp_group`)
- Why: starting, indexing, ready, and stopped are the same dot, so at 16 colors and under NO_COLOR, where the group colors collapse, they read alike; the crash and untrusted hints still name themselves.
- Fix: in the terminal-byte proof of NO_COLOR and 16 colors (`ui-groups-c`), decide whether the dot needs a second glyph for stopped.
### The folder cannot be dropped on a narrow bar
- Location: `carat/adapters/status_bar.rb` (`paint_file_name`, `fit`)
- Why: the folder is part of the file entry, which is never dropped, so a long path takes the width a narrow bar's other segments need before the file is cut.
- Fix: draw only the last segment of the path when the bar is narrow, or give the folder its own entry of low priority.
### The lsp group is computed twice per paint
- Location: `carat/adapters/status_bar.rb` (`paint_entry`, `paint_lsp`)
- Why: `paint_lsp` and the closing space in `paint_entry` each call `lsp_group`, a small duplication kept because returning the column and the group together would allocate each frame.
- Fix: keep the group in an integer instance variable that `paint_lsp` sets and `paint_entry` reads.
### A feature is sized by its testable parts only, not by its map areas and code files (recent-files-persist retro note 6)
- Location: .claude/agents/planner.md
- Why: recent-files-persist touched 11 code files in 4 areas (ports, drivers, doubles, adapters) and was estimated medium; implement took 469,082 of 542,318 output tokens (86%) and 249 of 337 tool calls (74%), reached its cap once, 2.7x over the 200,000 medium output budget. Near the backlog-lane item `split-at-placement`.
- Fix: count map areas and code files in the size check at placement; accepted when the next three features estimated medium stay under their output budget or are split at placement.

### A Low security finding in the change's own new code costs a full fix round (recent-files-persist retro note 7)
- Location: .claude/workflows/deliver-change.js
- Why: recent-files-persist spent 77,403 output tokens (504,196 minus 426,793, 14% of the run) plus a second check (tools-test 354s, test-build 292s, diagnose 355s) and a second security review finding 0, while no finding blocked. Near the backlog-lane item `nonblocking-round` (review-in-openspec note 10).
- Fix: fix a non-blocking finding in place only at a cost bounded in the brief, else append it to the findings file; accepted when over three deliveries metric.rework counts only rounds a blocking finding or a red CI started.
