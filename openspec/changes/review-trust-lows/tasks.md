# Tasks

## 1. The instruction records

- [ ] 1.1 `tools/gates.sh`: `INSTRUCTION_RECORDS_RE` and `settled_at` refusing a diff touching one (proved by the tools-test cases "gates: security refuses after an instruction record changed" and "gates: stages refuses a check before an instruction record changed", and "gates: security passes after the backlog and findings only")
- [ ] 1.2 `tools/run_state.sh`: the same line; `settled_round` and `reviewed_edits` follow it (proved by "run_state: settled refuses an instruction record", "run_state: reviewed-edits names an instruction record", and "rules: the instruction records are the gates'")

## 2. Docs

- [ ] 2.1 `README.md` and `docs/codebase-map.md` area 1 (proved by `make docs-lint`)
