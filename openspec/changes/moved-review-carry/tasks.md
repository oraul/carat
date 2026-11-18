# Tasks

## 1. Run state

- [ ] 1.1 Rewrite `moved_change` in `tools/run_state.sh`: three name lists with their statuses checked, the change's files compared as text, HEAD matching main in every file the reviewed change never touched, the `moved` record written only on the exit-0 path; proved by "moved reruns the reviews when the merge reverted a main-only file", "moved compares a file named like a pathspec literally", "moved reruns the reviews when git diff fails", and the existing "moved keeps the reviews when the merge changed no file of the change" and "moved reruns the reviews when a file of the change changed" in `tools/tools_test.sh`
- [ ] 1.2 Refuse a `carried=1` review in `tools/run_state.sh` `review` unless the `moved` record names its commit, and refuse `moved` in `set`; proved by "a carried review is refused without moved at the head", "a carried review is recorded after moved exits 0", and "set refuses the moved record"

## 2. Workflow

- [ ] 2.1 Say in the comments of `carried` and `carryReviews` in `.claude/workflows/deliver-change.js` that the shell backs the carry (comments only; the existing "workflow:" carry cases)

## 3. Docs and checks

- [ ] 3.1 Update `README.md` and `docs/codebase-map.md` (docs only; `make docs-lint` and `make gates`)
- [ ] 3.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
