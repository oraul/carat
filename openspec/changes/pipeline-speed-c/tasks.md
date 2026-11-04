# Tasks

## 1. Check (a and folds)

- [x] 1.1 `tools/run_state.sh`: `check` refuses a dirty tracked tree and an untracked file under `carat/`, `bin/`, `test/`, or `bench/`. Tested by the `tools/tools_test.sh` cases "run_state: check refuses modified tracked files" and "run_state: check refuses an untracked source".
- [x] 1.2 `tools/run_state.sh`: `check` no longer writes `phase.check`. Tested by "run_state: check leaves phase.check to the workflow".
- [x] 1.3 `tools/run_state.sh`: `code_key`, `COMPILE_STAGES`, and `build/pipeline/compiled`; a compile stage skips code it passed with its outputs unchanged. Tested by "run_state: check skips a compile stage on the code it passed", "run_state: check runs a compile stage after a code change", "run_state: check runs a compile stage whose outputs changed", "run_state: a tooling commit keeps the code key", and "run_state: a failed compile stage keeps no pass".
- [x] 1.4 `.claude/agents/checker.md`: the skipped compile stages in its report.

## 2. Notes and budget (fold, b)

- [x] 2.1 `tools/run_state.sh`: `add_note` strips one commit pattern. Tested by "run_state: note keeps one advisory starting with a hex word".
- [x] 2.2 `tools/run_state.sh`: `budget` prints `under:` and no dash for missing minutes. Tested by the budget cases, now `under:`, and "run_state: budget names no minutes when none were recorded".

## 3. One closing start (b)

- [x] 3.1 `tools/agent_guard.sh`: the `close` profile. Tested by "guard: close records a closing phase", "guard: close refuses a check phase", "guard: close refuses a review record", and the hook cases of every agent file.
- [x] 3.2 `.claude/agents/retrospective.md` takes the report and the record line with the `close` hook; `.claude/agents/reporter.md` removed.
- [x] 3.3 `.claude/workflows/deliver-change.js`: the closing start, its fallback to the record agent, the periodic review after it. No test runs the workflow script: checked by a syntax check and a simulation with stub agents (a merged run that records in the closing start, one whose start could not record and hands its lines to one record start before a due periodic review, and a resume after the retrospective).

## 4. Docs and bookkeeping

- [x] 4.1 `CLAUDE.md`, `README.md`, `docs/codebase-map.md` area 1, and the headers of `tools/run_state.sh` and `tools/agent_guard.sh`.
- [x] 4.2 `docs/backlog.md`: the three entries of `build/plan/backlog.md` added; the entries this change fixes removed (the `phase.check` write, `add_note`'s two patterns, the dirty tree, and the minute dash); the six `buffer-substitute` advisories marked 'Queued in `substitute-tidy`'.
- [ ] 4.3 Package step: the `buffer-substitute` row through `sh tools/run_state.sh history`, `build/plan/queue.md` and `goals.md` over `docs/`, and the minute-dash fold removed from the `pipeline-durability` item.
- [x] 4.4 Run `make tools-test`, `make docs-lint`, `make gates`, and `openspec validate pipeline-speed-c --strict --no-interactive`.
