# Tasks

## 1. Check records the workflow backs (c)

- [x] 1.1 `tools/run_state.sh`: `check CHANGE [COMMIT]` counts a stage record only at COMMIT. Tested by the `tools/tools_test.sh` cases "run_state: check runs a stage recorded at the head that no commit backs", "run_state: check skips the stages passed at the backed head", and the carry cases with the backed commit.
- [x] 1.2 `tools/gates.sh`: `stages` requires `phase.check` and every stage at its commit; `records` compares `check` with `phase.check` and requires a security record. Tested by "gates: stages refuses a stage at a commit the check record does not name", "gates: stages refuses without a check record", "gates: records compares the check record", "gates: records refuses a check record other than the workflow's", "gates: records refuses a check record the run state lacks", and "gates: records refuses without a security record".

## 2. Merge integrity (d)

- [x] 2.1 `tools/gates.sh`: the merge group adds `stages`, the stage list read from the copy's `Makefile`; `passed` refuses a dirty tracked tree. Tested by "gates: passed refuses a dirty tree" and "gates: merge runs from a copy of main against the branch".
- [x] 2.2 `tools/agent_guard.sh`: the merger runs `tmp/.merge-gates/tools/gates.sh merge` only; the read profile adds `run_state.sh scope`. Tested by "guard: merger runs main's merge gates", "guard: merger refuses the branch's merge gates", "guard: merger refuses another script under the worktree", and "guard: quality reviewer scopes a fix round".
- [x] 2.3 `.claude/agents/merger.md`: the merge gates command as given, its exit status, and the checked head as the expected head.

## 3. Reviews and their scope (a, b, folds)

- [x] 3.1 `tools/run_state.sh`: `scope CHANGE COMMIT [FILE...]`. Tested by "run_state: scope allows a fix of the named files and tests", "run_state: scope falls back for a file the findings do not name", "run_state: scope falls back when nothing changed", "run_state: scope counts both paths of a rename", "run_state: scope refuses a path with a parent step", and "run_state: scope refuses a commit that is not one".
- [x] 3.2 `tools/run_state.sh`: `note` keeps one `quality-advisory` per text. Tested by "run_state: note keeps one advisory across commits".
- [x] 3.3 `.claude/workflows/deliver-change.js`: parallel reviews and one fix round, the named files and `priorQuality` with `scope`, `phase.check` recorded and passed to the checker, `check` in `RECORDS`, `mergeGates()` from `origin/main`, `addAdvisories` without the commit, the `listed` rename. No test runs the workflow script: checked by a syntax check and a simulation with stub agents (both reviews blocking in one round, a fix round given `scope`, a resume, the merge command).
- [x] 3.4 `.claude/agents/checker.md` and `quality-reviewer.md`: the backed commit and the scope instruction.

## 4. Docs and bookkeeping

- [x] 4.1 `README.md`, `CLAUDE.md` (the `check` and `scope` commands, the bytes partly taken from the restated `usage` note), `docs/codebase-map.md` area 1 and its delivered-changes line, the headers of `tools/run_state.sh`, `tools/gates.sh`, and `tools/agent_guard.sh`.
- [x] 4.2 `docs/backlog.md`: the plan notes (the scratch-file entry added; the four entries this change fixes removed; the Queued lines added), and the narrowed entry for the `phase.check` that `check` still writes, queued in `pipeline-speed-c`.
- [x] 4.3 Run `make tools-test`, `make docs-lint`, `make gates`, and `openspec validate pipeline-speed-b --strict --no-interactive`.
