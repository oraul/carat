# Design

## Context

`tools/run_state.sh check_stages` runs `make -s stages` in order; a stage record counts only at the commit the workflow backs, or carried from it past a test-only commit, and every other stage runs. A change touching only tooling therefore compiles the editor and the test runner and runs `spinel-doctor` on code `main` already passed. After the merge `.claude/workflows/deliver-change.js` starts the retrospective, then the reporter, then a record agent (`flush`) for the phase lines queued since `verify()`'s flush and the metric line. The record agent has no agent type, so no hook: it is the only start that may run `tools/run_state.sh phase`, which the guard refuses to every profile. The scout pack `tmp/scout/build-and-ci-206f1b7-20261104T094302Z.md` holds the line references; they hold at 206f1b7.

## Goals / Non-Goals

Goals: no compile stage for code already compiled and checked; one closing start; the folds in the same functions. Non-goals: the tool-call cap and the early budget note (`run-budgets`), the killed or superseded check (`pipeline-durability`), any CI change.

## Decisions

### (a) The compile stages skip code they already passed

`code_key` hashes `git ls-tree -r --full-tree HEAD` without the paths no compile stage reads (`NOT_COMPILED`: `.claude/`, `.github/`, `docs/`, `openspec/`, `tools/*.sh`, top-level `*.md`), except `tools/analysis_budget.sh`, which `dev-build` and `test-build` run (`BUILD_TOOLS`). The `Makefile` is in the key, so the Spinel pin and the flags are too; `test/` is in it whole, snapshots included, which only makes the skip rarer.

For each of `COMPILE_STAGES` (`dev-build`, `test-build`, `diagnose`) `check_stages` keeps one line in `build/pipeline/compiled`: the stage, the key it passed on, and the checksum of its outputs (`build/dev/carat` and its `.timing` report; `build/test/run_all` and its report; none for `diagnose`). The line is dropped before the stage runs and written after it passes, so a failed or killed run leaves none. A stage whose line holds the current key and whose outputs still have that checksum is skipped and recorded as `0 0s HEAD TIME compiled-KEY`, which the stages gate reads as a pass at `HEAD`; the output checksum catches a runner that `make test` or `make snapshots` rebuilt from other code since. The existing skip at the backed head and the carry past a test-only commit come first, unchanged.

The file lies in the run state's directory, which only `tools/run_state.sh` writes: the guard refuses every agent a word naming it. The key is kept across changes because the first check of a change is the one that compiles: the previous run left its build, and a tooling change has the same code key as the `main` it starts from. Keyed on content rather than on the diff from `main`, the skip needs no base and holds for every round.

CI keeps its scope rule: `tools/ci_scope.sh` runs `spin check` for any path outside the documentation paths, `tools/` included, so CI still compiles both roots on any code path. `diagnose`, which CI leaves out, runs whenever the code key changes.

Alternative rejected: skipping on "the diff from `origin/main` touches no compiled path" alone, since the binaries in `build/` may come from another branch, and `test-run` and `metrics` use them.

### Check refuses a dirty tree and records no phase

`check_stages` first refuses when `git status --porcelain --untracked-files=no` is not empty or `git ls-files --others --exclude-standard` lists a file under `carat/`, `bin/`, `test/`, or `bench/`, the paths `spin` compiles, so no stage record and no compile key describes code that is not the commit. It no longer writes `phase.check`: the workflow on `main` records it from the checker's result (`phaseDone`, since `pipeline-speed-b`) and flushes it before the package step, where the stages gate reads it.

### (b) One closing start

The run ends with one `retrospective` start in every case. The script first queues the phase lines of this start (`retro` when the change merged and no retrospective ran, and `report`), joins them after the lines queued since the last flush, and appends the metric line. The agent, given that line, the figures, and the notes, proposes and budgets when the change merged, runs `review-due`, runs the record line last, and returns the report with `recorded`. When the periodic review is due the script runs it after the start and appends its result to the report. When the start returned nothing or `recorded` is false, the lines go back to the queue and one record start runs them, as before, so a run whose hooks still load the old profile or agent file loses nothing. A queued line other than a phase line of `CLOSE_PHASES` or a note (none occurs after `verify()`'s flush, but a stop could leave one) goes through the record agent before the closing start.

The guard's `close` profile is the `read` profile plus `tools/run_state.sh phase CHANGE NAME COMMIT` with NAME one of plan, implement, package, ci, merge, retro, report. It never runs `review` or the phase of check, quality, security, or bench, the records the merge gates compare, so a closing agent misled by text it reads cannot pass a merge. Merging the reporter into the retrospective puts the report on the session's model; the reporter's shape is kept in the retrospective's file.

### The budget line

`budget_line` prints `under:` where it printed `within:`, so the line reads as a comparison with the budget, and names the minutes only when `metric.wall_min` is set (the dash of `docs/backlog.md`).

### add_note's commit

The quality-advisory comparison strips a leading commit of 7 to 40 hexadecimal digits on both sides in one `awk` function, so a text whose first word is made of hex letters (`add`, `dead`) is compared whole on both sides.

## Risks / Trade-offs

- A forged `compiled` line would skip `diagnose`, which CI does not run; only `tools/run_state.sh` writes the directory, and branch code the checker runs could already write any stage record there.
- The installed toolchain is not in the key, only its pin in the `Makefile`; `make doctor`, the first stage, checks the tools.
