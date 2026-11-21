# Tasks

## 1. The check, the guard, and the lane facts

- [x] 1.1 `tools/agent_guard.sh`: the contributor runs `run_state.sh check CHANGE`, never with a COMMIT; tools-test cases `guard: contributor runs the check of its change` and `guard: contributor refuses a check that backs a commit`.
- [x] 1.2 `tools/run_state.sh` check: a COMMIT other than `phase.check` or HEAD is refused; header and comments document the trust; tools-test `run_state: check refuses a backed commit other than phase.check or the head`, the carry cases recording `phase.check`.
- [x] 1.3 `tools/lane_facts.sh`: the `machinery` line; tools-test cases for no, yes after a tools/ commit, and the existing lines.

## 2. The workflow

- [x] 2.1 `deliver-change.js`: WORK `check` and `check_runs`, `claimedPass` and `backedCommit`, the Check phase backing the claimed head, `parseLaneFacts` reading `machinery`; tools-test cases: the checker backs the contributor's passing head, keeps `phase.check` when the machinery changed, after a false or stale claim, and for a non-passing line.
- [x] 2.2 `deliver-change.js`: the `self_fix` metric seeded, summed, and in the metric line; tools-test case.
- [x] 2.3 `deliver-change.js`: CALL_CAPS implement 110, fix 60; SELF_CHECK asks for the check; `CONTRIBUTOR_CARD` rule 2; contributor.md maxTurns 170 (caps tests).

## 3. Documents

- [x] 3.1 `.claude/agents/contributor.md` line 15, card rule 2, implement step 5, fix; `docs/contributor-notes.md` Checking; within the 6999-byte budget.
- [x] 3.2 `openspec/config.yaml` apply guidance; `.claude/agents/checker.md`; CLAUDE.md; README.md; `docs/goals.md`; `docs/codebase-map.md`; the Sprint 25 exception line through the plan's `plan-apply` at package (the lane queue budget).

## 4. Checks

- [x] 4.1 `make tools-test`, `make docs-lint`, `make gates`, `make spec-validate`.

## Quality review

- [x] 5.1 `.claude/agents/contributor.md:51`: trimming step 5 for the budget dropped the checklist points the step must name; restored in shorter words, proved by the tools-test case `contributor: the self-check names each checklist point and the self-review` (fixed).
- [x] 5.2 `.claude/workflows/deliver-change.js` CALL_CAPS comment did not say why implement and fix rose; it now names the self-check runs (fixed, the caps cases unchanged).
- [x] 5.3 `tools/tools_test.sh` close harness: metricLine read an undefined selfFix and the figure count was stale; `workflow: the close's metric line carries every figure, self_fix among them` (fixed).
- [x] 5.4 `.claude/workflows/deliver-change.js` rounds: the backed commit's wiring had no test; `self-check: rounds builds the check line on backedCommit over the claim, the head, and phase.check` (fixed).
- [x] 5.5 `tools/run_state.sh` history: self_fix has no history column, since this change may not touch the feature lane's history file; recorded in `docs/findings/contributor-self-check.md` (recorded).
- [x] 5.6 `.claude/workflows/deliver-change.js` extraRuns: check_runs is self-reported and not compared with the runner's verdicts; recorded in `docs/findings/contributor-self-check.md` (recorded).

## Fix round

- [x] 6.1 Security review (Low) `.claude/workflows/deliver-change.js` claimFrom and `tools/run_state.sh` check: the comments said the stage records come only from a runner no agent writes, false for the contributor, whose working tree's runner writes them; the check entry, `backed_commit`, the claim comment, and the design's Context and Risks now say a backed head trusts the contributor's session and what CI and main's merge gates rerun (fixed, comments only). Signing the runner's records or always rerunning diagnose and gates adds behavior, so it stays recorded for `docs/findings/contributor-self-check.md`.
