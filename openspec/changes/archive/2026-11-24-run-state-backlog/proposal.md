# Proposal

## Why

`docs/backlog/tools/run_state.sh.md` holds 200 open entries against `tools/run_state.sh`, 36 of them security (2 Medium), the largest group of the backlog. The user asked for every one to be closed in one delivery, each by a fix with a tools-test case, by evidence that the base already fixed it or no longer holds the code, or by merging it into the entry it repeats. This change works the list theme by theme, security first, and records each entry's outcome in `docs/findings/run-state-backlog.md`.

## What Changes

- Check sandbox: stages run with a throwaway HOME inside the check clone and no XDG configuration directory; the escape scan also reads the XDG git configuration, the shell startup files, and the agent hooks' settings of the real HOME, and an unset HOME skips only its own files; the scan reads the main checkout's tracked paths NUL-separated, so a path holding a tab or newline is no untracked file; the scan's `ls-remote` runs with git's terminal prompt off and a time limit; the main checkout switched to another branch at the same commit counts as moved; links a stage plants in `build/` stay out of the carry.
- Compile cache: a pass is keyed by the code key and the make command, `dev-build`'s code key leaves out `test/` and `bench/`, and a compile stage that passed while the check stopped is noted as compiled, through one `compile_passed`.
- Lanes, merge, push: `lane-open` checks the branch with `valid`, `lane-open` and `lane-close` remove a worktree through one `lane_remove`, `lane-open` reads origin's own answer for `main` and the branch before it starts a worktree, `lane` prints no shell error for a missing queue, `merge-main` shows git's own message when a merge fails with no conflicted file, and `push --pr-text` accepts only a rewrite of the archived `pr.md`.
- Groom and fold: the fold drops `none`/`None` placeholder lines and writes each reference to a findings file, which groom removes, as the removed file, in the findings and in the carried backlog, so groom's output passes docs-lint; `plan-apply` appends each plan entry to the findings file once, after a blank line; `history` names the lane file it appended to.
- Plan-needed and tidy-ups: `review_runs` and `full_commit` replace the repeated review-run listing and commit resolution, `planned_commits` reads through `read_key`, the plan-needed line names the later passing review condition, `write_key` and `drop_key` share `state_rewrite`, `budget_line` and `spent_line` share `budget_of`, `check_lost` reads the stage records through `keys_under`, the stage-list comments sit above their functions, the usage header keeps its refusal paragraph after the list and says what `init` refuses, `SPRINT_HEADER` goes, the header names the `compiled-KEY` suffix, `tools/run_state.sh` returns to mode 100644, and `CLAUDE.md` and `docs/codebase-map.md` say what they should.
- Also in this part: `runner_wait` bounds the runner's wait by the clock, `dirty_tracked`, `verdict_failed`, and `recorded_check` replace repeated lines of the check, `merged_rows` and `on_head_or_base` replace repeated loops of the pending and merged tests, `EXCEPTION_MARK` is renamed `BEYOND_SPRINT_MARK`, `base-figures save` refuses any untracked file of the base worktree, and `plan-apply` leaves a planned `goals.md`, naming it, once a security review passed.
- Findings: every entry the start closes is listed under its heading in `docs/findings/run-state-backlog.md` as fixed, already fixed, gone, merged, or not fixed with the reason.

This is the first part of the delivery: the entries not yet in the findings file are the remaining work of the next start, named in its tasks (section 6), and split by theme if the run stops at its round limit.

Assumptions: an entry whose fix needs an edit of `tools/rules.sh` is not fixed here, since the merge gate reads that file and an edit of it goes first, alone; a security entry needing an operating-system sandbox (a stage's detached child after the scan) is not fixed, and its reason is recorded; the work list is read in its heading order only to name outcomes, the themes below fix several headings at once.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/run_state.sh`, `.claude/workflows/deliver-change.js` (one comment).
- Tests: `tools/tools_test.sh`.
- Docs: `CLAUDE.md` (the run_state.sh bullet), `docs/codebase-map.md` (the run_state.sh entry).
- README.md: unchanged, a tooling change whose behavior the README does not describe at this level.
- docs/architecture.md: unchanged, no layer, port, or rule moves.
- docs/compatibility.md: unchanged, no Neovim command is touched.
- docs/actions.md: unchanged, no action is bound or changed.
