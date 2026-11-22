### The checker starts when every stage is carried from the contributor's pass (buffer-picker retro note 2)
- Location: .claude/workflows/deliver-change.js, the check phase; near backlog queue Pool 16 `check-at-head`, merge into it.
- Why: buffer-picker check 33,344/2 (9.0 percent of 369,656 output) with every stage skipped as passed at the same head; check 59,290/2, 24,047/2, 32,471/2 in cmdline-completion, set-options, colorscheme-command.
- Fix: no check agent when all stages are carried at the head; accepted when the next 3 such runs record no check agent tokens and first.check stays 1.

### A one-area change still gets a scout pack (buffer-picker retro note 3, merge-gate-lows retro note 4)
- Location: .claude/workflows/deliver-change.js, the areas and scout phases; near backlog queue Pool 14 `scout-prune` and `areas-in-plan`, merge into them.
- Why: buffer-picker scout 37,539/22 (10.2 percent of output) for 1 area, implement still 74 calls; merge-gate-lows plan 20,300/13 relocated the lines, scout 18,783/13 packed the same area, the contributor relocated them again.
- Fix: no scout for one area or for lines the plan names; accepted when the next 3 one-area feature runs record no scout phase, implement at or under 83.5 calls, first.check 1.

### The merger spends about half its calls polling CI (buffer-picker retro note 4)
- Location: the merge phase of .claude/workflows/deliver-change.js; near backlog queue Pool 14 `merge-wait-bound`, merge into it.
- Why: ci_wait_calls 6 of merge's 13 calls (46 percent) for a 12.0 min CI; 6 in 8 of the last 10 feature rows.
- Fix: wait outside the agent; accepted when the next 3 runs record ci_wait_calls 0 or 1 and merge at most 8 calls, first.ci unchanged.

### The budget line clips a records run's own tokens at zero (merge-gate-lows retro note 2)
- Location: tools/run_state.sh `budget`; near backlog queue Pool 13 `budget-recalibrate` and "### The in-run budget line prices total tokens at 6 per output token", merge into it.
- Why: budget sprint-26-records printed 0 total with 34,373,476 set apart, against the row's 2,612,300 total.
- Fix: accepted when budget sprint-26-records prints a nonzero total no larger than 2,612,300 and set-apart plus own tokens match the records.

### Packaging spends two agent starts on a fixed sequence (merge-gate-lows retro note 3)
- Location: .claude/workflows/deliver-change.js, the package and prtext starts.
- Why: package plus prtext 23 of 128 calls (18.0 percent) in merge-gate-lows; 24 of 258, 32 of 241, 47 of 239, 48 of 297 in config-guards-b, pipeline-lows-a, contributor-harness, contributor-self-check.
- Fix: accepted when package and prtext take at most 10 calls together over the next 3 backlog runs, gates and ci first passes unchanged.

### The closed fold's text is not the design's chevron and count
- Location: carat/domain/folds.rb:316 to :326 (`label`, Neovim's `+--N lines: text` filled with FILL), against docs/design.md:75 and :76 (a faint `▸` for a fold's closed gap, a dim `⋯ 12 lines` count).
- Why: folded-row paints the row in its own dim group, `Folded`, as the brief asks, but the text still differs from the binding look, and docs/design.md section 7 lists no Known drift row for it.
- Fix: decide the fold text (keep Neovim's default or draw `▸ first line ⋯ N lines`), then change `Folds#label` and its scenarios in openspec/specs/folds/spec.md and the whitespace-marks test; or add the gap to the Known drift table with its closing item.

### The fold label's fill is not ASCII under option.icons ascii and NO_COLOR
- Location: carat/domain/folds.rb:21 (`FILL = "·"`), used by `label` at :316; the frame presenter's ascii switch at carat/adapters/frame_presenter.rb:244 does not reach it.
- Why: an ascii frame elsewhere holds no byte above 127 (test/adapters_frame_presenter.rb, the ascii frame check), but a closed fold's row still draws U+00B7 there, and under NO_COLOR, which asks for ASCII glyphs.
- Fix: pass the ascii flag to the label (or a fill string) and fill with `-` as Neovim's `fillchars` fold default does; a test drawing a closed fold under `option.icons ascii` asserting no byte above 127.
