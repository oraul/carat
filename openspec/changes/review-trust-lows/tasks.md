# Tasks

## 1. The instruction records

- [x] 1.1 `tools/gates.sh`: `INSTRUCTION_RECORDS_RE` and `settled_at` refusing a diff touching one (proved by the tools-test cases "gates: security refuses after an instruction record changed" and "gates: stages refuses a check before an instruction record changed", and "gates: security passes after the backlog and findings only")
- [x] 1.2 `tools/run_state.sh`: the same line; `settled_round` and `reviewed_edits` follow it (proved by "run_state: settled refuses an instruction record", "run_state: reviewed-edits names an instruction record", and "rules: the instruction records are the gates'")
- [x] 1.3 `tools/run_state.sh`: `moved_change` counts an instruction record as a file of the change through `outside_records`, shared with `reviewed_edits` (quality advisory at `moved_change`; proved by "run_state: moved reruns the reviews when an instruction record changed after the pass")
- [x] 1.4 `tools/run_state.sh`: `settled_round` filters through `outside_records` too, dropping its inline copy of the filter, with no change of behavior (quality advisory at `settled_round`; proved by "run_state: settled refuses an instruction record", "run_state: settled refuses a code change", and "run_state: settled refuses the sprints file")

## 2. Docs

- [x] 2.1 `README.md` and `docs/codebase-map.md` area 1 (proved by `make docs-lint`)
- [x] 2.2 `README.md` and `docs/codebase-map.md` area 1 name the instruction record `moved` counts (proved by `make docs-lint`)
