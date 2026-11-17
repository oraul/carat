# Tasks

## 1. Run state records

- [ ] 1.1 Check a CI head against the pushed head in `set CHANGE ci` and `phase CHANGE ci` (`pushed_at`, `tools/run_state.sh`); proved by "run_state: set refuses a CI head not the pushed head", "run_state: phase refuses a CI head not the pushed head", "run_state: set refuses a CI record before a push", and "run_state: set stores the pushed head as the CI head" in `tools/tools_test.sh`
- [ ] 1.2 Check a merged commit in `set CHANGE merged` and `phase CHANGE merge` (`merged_at`, `squash_commit`, `tools/run_state.sh`); proved by "run_state: set refuses a merged commit not on main", "run_state: set refuses a merged commit that is not the pull request's squash commit", "run_state: phase refuses a merge that is not the pull request's squash commit", and "run_state: set records the pull request's squash commit as merged" in `tools/tools_test.sh`
- [ ] 1.3 Add `sprint-row COMMIT` (`sprint_row_at`, `tools/run_state.sh`); proved by "run_state: sprint-row prints the row groom appended" and "run_state: sprint-row refuses a marker naming another sprint" in `tools/tools_test.sh`

## 2. Gate

- [ ] 2.1 Accept only groom's row in `settled_at` (`groom_row`, `tools/gates.sh`); proved by "gates: security passes after groom's sprint row", "gates: security refuses an edit of an earlier sprint row", "gates: security refuses a sprint row not groom's", "gates: security refuses a second sprint row", and "gates: security refuses a row for a sprint the marker does not name" in `tools/tools_test.sh`

## 3. Workflow and agents

- [ ] 3.1 Record the CI lines and `phase.ci` at the pushed head in `.claude/workflows/deliver-change.js`; the merger's sha checked by 1.2 (no test of the script; `make docs-lint`, `make gates`)
- [ ] 3.2 Copy the merged sha from git output in `.claude/agents/merger.md` and show the run state's merged commit in `.claude/agents/retrospective.md` (docs only; the guard cases in `tools/tools_test.sh` stay green)

## 4. Docs and checks

- [ ] 4.1 Name `settled_at` once in `docs/codebase-map.md` and list `sprint-row` in the run state's header (docs only; `make docs-lint`)
- [ ] 4.2 `make gates`, `make spec-validate`, `make docs-lint`, and `make tools-test` pass
