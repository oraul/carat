### Status bar has no folder segment and shows the server state as text
- Location: `carat/adapters/status_bar.rb` (`collect`, `paint_entry`, the `LSP` kind), `docs/design.md` section 8 (Status bar)
- Why: the design lists folder among the quiet segments and says the server state is one dot; the bar has no folder segment and the `lsp` slot is its name and state text, so those two parts of the design are not drawn.
- Fix: add a folder segment (a `StatusSlots` field a plugin or the project root fills) in `StatusLineDim`, and draw the server as one dot in its state group with the name in `StatusLineDim`; keep the `lsp` width table and `docs/compatibility.md` in step.

### The progress bar and the percent keep StatusLine
- Location: `carat/adapters/status_bar.rb` (`paint_bar`, the PERCENT and PROGRESS kinds)
- Why: the undone cells of the progress bar and the percent are drawn in the bold `StatusLine` beside quiet neighbours, while the design's hierarchy names only the file and the position as leading; the brief named the design's groups, so these were left as they were.
- Fix: draw the undone cells and the percent in `StatusLineDim` once the design says which; update the progress and percent scenarios and snapshots.

### The visual indicator is dim but ModeMsg and MoreMsg are still unused
- Location: `carat/adapters/frame_presenter.rb` (`paint_message`), `carat/domain/themes.rb` (`MESSAGE_MODE`, `MESSAGE_MORE` rows)
- Why: the `-- VISUAL --` indicators now use `MsgDim`, so `ModeMsg` (bold) has no caller and `MoreMsg` still has none; the theme rows are dead until a change uses or drops them.
- Fix: either draw the indicator in `ModeMsg` with a dim row, or remove the two groups with the renumbering, and add a `-- More --` pager only with a change that needs it.

### NO_COLOR and 16 colors are proven on the groups, not on the terminal bytes
- Location: `test/adapters_status_bar.rb`, `test/domain_theme.rb`, `carat/drivers/ansi_terminal.rb`
- Why: the tests assert the bar's cell groups under the presenter's plain mode and the group's 16-color and 256-color theme entries; no test writes the bar through the ANSI driver at 16 colors or with `NO_COLOR` to read the escape sequences, so a regression in how the driver maps `StatusLineDim` would not show.
- Fix: add a smoke case that draws the bar through the driver at 16 colors and under `NO_COLOR` and compares the written sequences for `StatusLine` and `StatusLineDim`.
### The contributor rules card is kept word for word in two places (review-in-openspec retro note 11, card-twice)
- Location: `.claude/agents/contributor.md` and `CONTRIBUTOR_CARD` at `.claude/workflows/deliver-change.js:879`
- Why: the same card text lives in both files and contributor.md has no room left under its docs-lint budget, so a rule edited in one place drifts from the other.
- Fix: keep the card's text in one tracked place; accepted when contributor.md keeps at least 500 bytes under its docs-lint budget and a tools-test case shows every implement start still receives each rule (pipeline, T1, critical b).

### The check phase costs a sixth to a third of a run's output while confirming stages that pass (review-in-openspec retro note 9, check-share)
- Location: the check phase of `.claude/workflows/deliver-change.js`; near the backlog queue's Pool 14 `check-carry`
- Why: review-in-openspec spent 121,585 of 724,443 output tokens (16.8 percent) on check over 3 passes, all passing.
- Fix: merge into `check-carry`; accepted when over the next three deliveries with first.check 1 the check phase stays under 8 percent of output tokens and CI finds no stage failure the check left out.

### A check is voided as escaped for a file the dev-build stage is declared to write (sprint-27-records note 1, security-escape)
- Location: `tools/run_state.sh:890` (the `security-escape` note) against `tools/run_state.sh:1659` (`dev-build` lists `build/dev/carat.timing`)
- Why: sprint-27-records recorded `escaped check` at 1df857f64fc4 for the lane's own `build/dev/carat.timing`, a declared output of `dev-build`, so a passing check can be voided and rerun.
- Fix: resolve the lane's `build/` link before comparing escaped paths with the stage's declared outputs; accepted when a tools-test check in a lane worktree writing `build/dev/carat.timing` records no `security-escape` note while one writing under `tmp/.toolchain` still does (pipeline, T1, critical b).
