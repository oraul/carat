# Tasks

## 1. The check sandbox

- [x] 1.1 Stages run with a throwaway HOME and no XDG configuration (`CLONE_EXEC`); the scan reads the XDG git configuration, the shell startup files, and the hooks' settings; an unset HOME skips only its files (`tools/run_state.sh`; tests: HOME, profile, XDG, unset HOME)
- [x] 1.2 The main checkout's tracked paths and files are compared NUL-separated; the scan's `ls-remote` runs with the prompt off and a time limit; the main checkout's branch is compared with its commit (tests: tab path, prompt, branch)
- [x] 1.3 Links a stage plants in `build/` stay out of the carry and the next clone (test: a link reaches no carry)
- [x] 1.4 A compile pass is keyed by the code key and the make command; `dev-build`'s key leaves out `test/` and `bench/`; a compile stage that passed while the check stopped is noted compiled (tests: make command, test/ and bench/, stopped check)

## 2. Lanes, merge, push

- [x] 2.1 `lane-open` reads origin's refs first and checks the branch with `valid`; `lane-open` and `lane-close` share `lane_remove`; `lane` prints no shell error; `merge-main` shows git's message on a failure with no conflicted file; `push --pr-text` accepts only the archived `pr.md` (tests for each)

## 3. Groom and fold

- [x] 3.1 The fold drops placeholder lines and writes references to removed findings files as the removed file (`fold_clean`, `removed_refs`); `plan-apply` appends each plan entry once after a blank line; `history` names the lane file (tests for each)

## 4. Plan-needed and tidy-ups

- [x] 4.1 `review_runs`, `full_commit`, `planned_commits` through `read_key`, the plan-needed line, `state_rewrite`, `budget_of`, `check_lost` through `keys_under`, the stage-list comments, the usage header, `SPRINT_HEADER`, mode 100644, `CHECK_BIN` (tests where behavior moved; the rest covered by the cases already there)
- [x] 4.2 Update `CLAUDE.md` and `docs/codebase-map.md`

## 5. Findings

- [x] 5.1 List each entry closed so far in `docs/findings/run-state-backlog.md`, one line of outcome each

## 6. Remaining work of the list

- [ ] 6.1 Every heading of `docs/backlog/tools/run_state.sh.md` the findings file does not yet name: the check sandbox rest (stage process group, the runner from a copy, logged record writes, refs and lane branches from the mark, `lane_open` fetching first), the groom proofs, the plan-needed group, the budget and history group, and the comment tidy-ups
