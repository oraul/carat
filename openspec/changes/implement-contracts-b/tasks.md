# Tasks

## 1. Lint: the code map's method lists

- [x] 1.1 `test/lint.rb`: `map_entry_path`, `map_methods`, `defines?`, and `map_method_problems`, run over every file line of `docs/codebase-map.md`. Tested by "the code map method rule" and "no lint violations" in `test/lint.rb`.

## 2. Lint: `Array[untyped]` of program objects

- [x] 2.1 `test/lint.rb`: `untyped_parameter?` with `UNTYPED_PARAMETERS`, and `list_assignment?` over the members pinned `Array[untyped]` with `UNTYPED_SHARED` (`styles`, owned by `hover-tidy`). Tested by "the untyped parameter rule", "the shared list rule", and "no lint violations" in `test/lint.rb`.

## 3. Gates: doc prose a change leaves behind

- [x] 3.1 `tools/gates.sh`: `gate_docs` refuses a spec change without `README.md` or `docs/architecture.md`, and a process file change without `CLAUDE.md`, unless a proposal in the diff says why. Tested by the "gates: docs ..." cases in `tools/tools_test.sh`.

## 4. Gates: scenarios no test names

- [x] 4.1 `tools/gates.sh`: `gate_scenarios`, in `static` and `pre-push`. Tested by the "gates: scenarios ..." cases in `tools/tools_test.sh`.

## 5. Records

- [ ] 5.1 `openspec/config.yaml`, `CLAUDE.md`, and `docs/codebase-map.md` name the new rules and gate. Checked by `make gates` and `make docs-lint`.
- [ ] 5.2 `docs/backlog.md`: add the planner's entries from `build/plan/backlog.md`, change three copies to four in "The gateway cancels a request in three copies", and point the `Buffer#styles` entry at the lint exemption. Checked by `make docs-lint`.
