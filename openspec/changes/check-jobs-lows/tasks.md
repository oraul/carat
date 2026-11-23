# Tasks

## 1. Job results from the runner

- [x] 1.1 Replace the jobs directory and its `.status` and `.start` files in `tools/run_state.sh` with the job subshell's exit status read by `wait` and a runner variable holding each job's pid, start, and commit; update `stage_launch`, `stages_reap`, `stages_stop`, and `check_run`
- [x] 1.2 Print the failing stage's log excerpt through `visible_text`
- [x] 1.3 Add `tools/tools_test.sh` cases: a stage writing a sibling's job files leaves its record alone, and an ESC sequence in a failing log is printed without the ESC byte

## 2. Docs

- [x] 2.1 Check README.md, CLAUDE.md, and `docs/codebase-map.md` still describe `check` correctly

## Quality review

- [x] 3.1 Self-review of the diff by the quality reviewer's checklist, each finding fixed or recorded

- [x] 3.2 Review finding (Low): the escape scan's changed-path list also prints unfiltered; it is outside the brief's outcome, so it is recorded in docs/findings/check-jobs-lows.md
