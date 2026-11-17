### lone_file_window? is evaluated once per window instead of once per tab page

- Location: carat/domain/buffer_list.rb:423
- Why: `lone_file_window?(tabs.tab_at(t))` runs for every window of the inner loop though it depends only on the tab page, so the walk repeats a per-tab-page test once per window (performance).
- Fix: compute it once per tab page before the window loop and reuse the value inside it.

### The E36 branch of open_file_window has no test

- Location: carat/use_cases/plugins/window_requests.rb:287
- Why: the branch that returns E36 for `close_scratch` on the editor's last window, replacing the old E444, is never exercised, so its message and the state it leaves are unproven (missing test).
- Fix: add a row closing a lone scratch window with no room for a split, or drop the branch if it cannot happen.
### The merge phase output on a green first-pass CI varies fivefold (check-parallel retro note 8)
- Location: .claude/workflows/deliver-change.js, the merge phase; queued in `merge-gate-integrity`
- Why: check-parallel's merge spent 22,685 of 239,451 output (9.5%) in 11 calls with 4 CI wait calls on a first-pass CI; of the last 20 lane rows 19 passed CI first, 6 of them above 10,000 merge output and the other 13 at 4,347 to 7,747.
- Fix: one CI wait and one merge per green run; accepted when over the next five runs whose CI passes first the merge phase stays under 8,000 output tokens.

### The check-pass budget step changes no decision (check-parallel retro note 9)
- Location: .claude/workflows/deliver-change.js, the budget step at the check pass; queued in `budget-prediction`
- Why: check-parallel printed "no spent line returned" at its check pass; the projection assumes 6 total tokens per output token while the last ten backlog rows ran 3.5 to 59.
- Fix: remove the step or fold it into the close budget line; accepted when over the next five runs every budget step prints an under: or over: line, or the close line is the only one.

### Quality advisories the package step drops as style (check-parallel retro note 10)
- Location: .claude/agents/quality-reviewer.md, the advisory classes; queued in `review-demotion`
- Why: check-parallel's package dropped 4 of 7 advisories as style, sprint-security 3 of 6; reviews 26,694 output (11.1%) and 26 of 133 calls; quality first pass 67/131.
- Fix: the reviewer stops reporting the classes the contributor drops unchanged; accepted when over the next five runs the package step drops none of the advisories reported.
