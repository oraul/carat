# Tasks

## 1. Late findings stamped by the merge

- [x] 1.1 `tools/run_state.sh` `add_note`: refuse a `late-finding` while `merged` names no commit on main, store it as `late-finding MERGED TEXT`; `late_findings`: keep only the stamp equal to `merged` and text in `noteText`'s shape, naming each left out; header lines of `note` and `history`. Test: `tools/tools_test.sh` "run_state: note refuses a late finding before the run merged", "run_state: history leaves out a late finding the workflow did not write".
- [x] 1.2 `.claude/workflows/deliver-change.js`: `recordLate` only for a merged run. Test: the existing history cases, and `make tools-test`'s workflow helpers.

## 2. The open-pr checkout and wait

- [x] 2.1 `.github/workflows/open-pr.yml`: `persist-credentials: false` on `Check out main`. Test: "repository: the open-pr checkout stores no token".
- [x] 2.2 `tools/open_pr.sh` `wait`: exactly one number on the pushed sha, or the recorded `pr` among them; else refuse. Test: "open_pr: wait records no pull request when a fork's shares the pushed head", "open_pr: wait keeps the recorded pull request beside a fork's on the pushed head".

## 3. One checks form

- [x] 3.1 `.claude/workflows/deliver-change.js` `staleRed`: name between the first field and the last two. Test: "workflow: a check name with commas is read whole".
- [x] 3.2 `.claude/agents/merger.md` step 2 and the merger schema: one `workflow, name, status, conclusion` form, the workflow from `actions_list` by check suite, `-` on green. Test: "agents: the merger returns every check in one form with the workflow's source".

## 4. Docs and checks

- [x] 4.1 `docs/codebase-map.md` area 1: `note`, `history`, `open_pr.sh`, and `open-pr.yml` lines. Test: `make docs-lint`, `make gates`, `make spec-validate`, `make check-stage S=tools-test`.
