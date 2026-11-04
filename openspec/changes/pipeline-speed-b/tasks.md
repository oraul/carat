# Tasks

## 1. Check records the workflow backs (c)

- [ ] 1.1 `tools/run_state.sh`: `check CHANGE [COMMIT]` counts a stage record only at COMMIT. Tested by the `tools/tools_test.sh` cases "run_state: check runs a stage recorded at the head that no commit backs", "run_state: check skips the stages passed at the backed head", and the carry cases with the backed commit.
- [ ] 1.2 `tools/gates.sh`: `stages` requires `phase.check` and every stage at its commit; `records` compares `check` with `phase.check` and requires a security record. Tested by "gates: stages refuses a stage at a commit the check record does not name", "gates: stages refuses without a check record", "gates: records compares the check record", "gates: records refuses a forged check record", and "gates: records refuses without a security record".

## 2. Merge integrity (d)

- [ ] 2.1 `tools/gates.sh`: the merge group adds `stages`, the stage list read from the copy's `Makefile`; `passed` refuses a dirty tracked tree. Tested by "gates: passed refuses a dirty tree" and "gates: merge runs from a copy of main against the branch".
- [ ] 2.2 `tools/agent_guard.sh`: the merger runs `tmp/.merge-gates/tools/gates.sh merge` only; the read profile adds `run_state.sh scope`. Tested by "guard: merger runs main's merge gates", "guard: merger refuses the branch's merge gates", "guard: merger refuses another script under the worktree", and "guard: quality reviewer scopes a fix round".
- [ ] 2.3 `.claude/agents/merger.md`: the merge gates command as given, its exit status, and the checked head as the expected head.

## 3. Reviews and their scope (a, b, folds)

- [ ] 3.1 `tools/run_state.sh`: `scope CHANGE COMMIT [FILE...]`. Tested by "run_state: scope allows a fix of the named files and tests", "run_state: scope falls back for a file the findings do not name", "run_state: scope falls back when nothing changed", and "run_state: scope refuses a commit that is not one".
- [ ] 3.2 `tools/run_state.sh`: `note` keeps one `quality-advisory` per text. Tested by "run_state: note keeps one advisory across commits".
- [ ] 3.3 `.claude/workflows/deliver-change.js`: parallel reviews and one fix round, the named files and `priorQuality` with `scope`, `phase.check` recorded and passed to the checker, `check` in `RECORDS`, `mergeGates()` from `origin/main`, `addAdvisories` without the commit, the `listed` rename. No test runs the workflow script: checked by a syntax check and a simulation with stub agents (both reviews blocking in one round, a fix round given `scope`, a resume, the merge command).
- [ ] 3.4 `.claude/agents/checker.md` and `quality-reviewer.md`: the backed commit and the scope instruction.

## 4. Docs and bookkeeping

- [ ] 4.1 `README.md`, `docs/codebase-map.md` area 1, the headers of `tools/run_state.sh`, `tools/gates.sh`, and `tools/agent_guard.sh`.
- [ ] 4.2 `docs/backlog.md`: the plan notes (the scratch-file entry added; the four entries this change fixes removed; the Queued lines added).
- [ ] 4.3 Run `make tools-test`, `make docs-lint`, `make gates`, and `openspec validate pipeline-speed-b --strict --no-interactive`.
