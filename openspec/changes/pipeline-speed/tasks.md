# Tasks

## 1. Totals and budgets

- [ ] 1.1 `tools/run_state.sh`: `usage CHANGE TOKENS MINUTES` adds a start's total tokens and wall minutes to `metric.total_tokens` and `metric.wall_min` and prints the budget line. Tested by the `tools/tools_test.sh` cases "run_state: usage adds the starts' totals" and "run_state: usage refuses a figure that is not a number".
- [ ] 1.2 `tools/run_state.sh`: `TOKEN_BUDGETS` on total tokens (500k, 1.2M, 2.5M), `MINUTE_BUDGETS` (small 25), `budget_line` comparing both and naming the output tokens. Tested by the budget cases of `tools/tools_test.sh` (overrun by tokens, overrun by minutes, within, unmeasured).
- [ ] 1.3 `tools/run_state.sh`: the history's columns 16 and 17, `total_tokens` and `wall_min`; `docs/metrics.tsv` gets `-` in both on every row. Tested by "run_state: history records the totals" and "run_state: every history row has the header's columns" (17).

## 2. Rework across starts

- [ ] 2.1 `.claude/workflows/deliver-change.js`: `mayFix()` for the review rounds and the CI fixes, `extra` and `stop` in the metric line and the seed, the `extra-round` note, the metric line first in the checker's prompt, and the last flush when a run stopped. Checked by `node --check` and a reading of the delta against the design (no test runs the workflow scripts).
- [ ] 2.2 `.claude/agents/checker.md`: run the given metric line first.

## 3. Periodic review areas

- [ ] 3.1 `tools/run_state.sh`: the `guard and gates` area and `agent_hooks`. Tested by the review-due cases "names the guard", "names the gates", "names the CI workflow", "skips another tool", "skips an agent's prose", and "names an agent's hook".
- [ ] 3.2 `.claude/workflows/periodic-review.js` and `.claude/commands/review.md`: the areas as worded.

## 4. Planner only when needed

- [ ] 4.1 `tools/run_state.sh`: `plan-needed CHANGE`. Tested by "run_state: plan-needed takes the queue head as written", "... names a change that is not the head", "... names a pending proposal", and "... ignores a delivery's advisories".
- [ ] 4.2 `.claude/workflows/deliver-change.js`: the resume runs `plan-needed`; the planner runs only when it says needed or for a brief beyond the change name; `planned` stored; the package prompt for a skipped plan. `.claude/agents/contributor.md` package step 2 and `.claude/agents/planner.md` step 3.

## 5. Retrospective, deliver command, and docs

- [ ] 5.1 `.claude/agents/retrospective.md`: budget of the history's last change, overrun note. `.claude/commands/deliver.md`: the `usage` step.
- [ ] 5.2 `CLAUDE.md` (hard rule, planner, commands, room taken from wording), `README.md`, `docs/codebase-map.md` area 1, `tools/run_state.sh` header, `tools/agent_guard.sh` read profile if an agent runs a new command.
- [ ] 5.3 `docs/backlog.md`: goal numbers at the search and goal-11 entries, the Queued lines the planner named, the CLAUDE.md room entry when 1,000 bytes are free.
- [ ] 5.4 Run `make tools-test`, `make docs-lint`, `make gates`, and `openspec validate pipeline-speed --strict --no-interactive`.
