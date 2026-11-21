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
- [x] 3.2 `openspec/config.yaml` apply guidance; `.claude/agents/checker.md`; CLAUDE.md; README.md; `docs/goals.md`; `docs/codebase-map.md`; `docs/queue-backlog.md` exception line.

## 4. Checks

- [ ] 4.1 `make tools-test`, `make docs-lint`, `make gates`, `make spec-validate`.
