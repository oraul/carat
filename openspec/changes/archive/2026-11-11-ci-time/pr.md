chore(pipeline): record CI stages and tier-weighted tokens per delivery

## Summary

Records each CI step's seconds, the merger's tool calls spent waiting on CI, and every agent start's tokens weighted by its tier's price, and skips the CI checks again when a pull request that already passed changes only documentation no test reads. CI took 4.6 to 17.0 minutes over the last pull requests with only one figure recorded, documentation-only follow-up commits rebuilt everything, and raw token totals could not show the effect of any cost item.

---

## Changes

- Add `tools/run_state.sh ci-stages`, which reads the spin job of the newest CI run at a commit and records each step's seconds as a metric, queued by the workflow for the record or closing start once CI is green or red.
- Add `tools/run_state.sh tokens`, which sums each agent start's input, cache, and output tokens from a Workflow run's transcripts, prices them by tier, and records per-start, per-phase, and total weighted tokens; `/deliver` runs it after each Workflow start.
- Change `tools/ci_scope.sh` to treat `.claude/agents/`, `.claude/workflows/`, and `.claude/settings.json` as code, and to skip the checks when the merge differs from the newest green head of the pull request only in documentation no test reads, with `.github/workflows/ci.yml` passing the pull request's number and head.
- Add the merger's CI waiting calls, counted from the minutes it returns, as a metric in the run state.
- Add columns 19 to 22 to `docs/metrics.tsv` for the CI stages, the waiting calls, the weighted tokens, and the weighted phases, padding the existing rows.
- Allow the new command in the close profile of `tools/agent_guard.sh` and add tools test cases for the CI scope, the stages, and the token pricing.
- Document the commands and the measurement in CLAUDE.md, README.md, `docs/architecture.md` section 10, the code map, and the deliver command.
- Record the planner's queue, the sprint-planning metrics row, and eight quality advisories in the backlog.

---

## Testing

- Run the security review of the committed diff, pass with no findings.
- Run the quality review, pass with no blocking finding and eight advisories, appended to `docs/backlog.md`.
- Run the benchmark review, pass with no blocking finding.
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run `make spec-validate` after archiving, all 51 items pass.

---

## Notes

The change alters no editor behavior and is archived without delta specs. The merger's own command lines are unchanged because its guard is the copy on main, which would refuse a new command during this change's own merge. Judging the acceptance figures (CI under 10 minutes and documentation-only checks under 60 seconds over three runs) is left to the next metrics rows.
