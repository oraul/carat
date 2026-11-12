# Tasks

## 1. One records-only list

- [x] 1.1 `tools/rules.sh` (`RECORDS_RE`), `tools/gates.sh` (`settled_at`), `tools/run_state.sh` (`TEST_ONLY`), `tools/ci_scope.sh` (`documentation`): name the records-only paths once, `docs/sprints.tsv` among them. Tested by "rules: the records-only list is named once" and "ci_scope: docs/sprints.tsv on a pull request" in `tools/tools_test.sh`.
- [x] 1.2 `tools/gates.sh` (`appended_rows`, `settled_at`): accept a `docs/sprints.tsv` change only when it appends rows. Tested by "gates: security refuses an edit of an earlier sprint row" and "gates: security passes after a row appended to the reviewed sprint rows".

## 2. Records applied once

- [x] 2.1 `tools/run_state.sh` (`groom`, `sprint_applied`): apply a plan once, saying so when the sprint's row stands, and retire the marker. Tested by "run_state: groom retires the applied plan's marker" and "run_state: groom says a sprint's row already stands".
- [x] 2.2 `tools/run_state.sh` (`append_history`): no second row for a run whose row a package step appended or main holds. Tested by "run_state: history appends no row a run already has" and "run_state: history appends no row main already has".

## 3. Records excluded by the brief

- [x] 3.1 `tools/run_state.sh` (`records_excluded`, the `history` and `groom` arms): `history CHANGE` and `groom CHANGE` do nothing for a run state with `records=skip`. Tested by "run_state: history honors the records exclusion" and "run_state: groom honors the records exclusion".
- [x] 3.2 `.claude/workflows/deliver-change.js` (the `PLAN` schema, the plan and package phases) and `.claude/agents/contributor.md` (package step 2): set the key from `input.records` or the planner and pass the change to both commands. Checked by `make tools-test` and `make docs-lint`.

## 4. Docs and checks

- [x] 4.1 `CLAUDE.md`, `README.md`, `docs/codebase-map.md`: name the behavior. Checked by `make gates` and `make docs-lint`.
- [ ] 4.2 Run `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate`, all pass.
