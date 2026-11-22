# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-28-records`: take in a moved main. Checked by its output, "holds origin/main".
- [x] 1.2 `tools/run_state.sh history sprint-28-records`: append the pending rows to the metrics files. Checked by the rows in the diff.
- [x] 1.3 `tools/run_state.sh groom sprint-28-records`: file the findings, copy the queues, append the sprint row. Checked by its output, "applied sprint-28".

## 2. Checks

- [ ] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.

## 3. Queue fixes

- [x] 3.1 `make docs-lint` failed on the backlog sprint's 5 items over the cap of 3; by the user's answer of 2026-11-22, `plugin-host-lows` and `config-trust-tidy` move unchanged to Pool item 1, marked for Sprint 30 beside `planner-loop`, the Pool renumbered, and the exception line and the Sprint 29 decision reworded so `scout-drop` and `cheap-tier` are the two pipeline changes within the sprint's 3, `scout-drop` first and alone. Checked by `make docs-lint`.
- [x] 3.2 As the sprint-27 records change did, add the word "estimated" before each Pool size of both queues and drop the backticks on the nonexistent .claude/settings.local.json path. Checked by `make docs-lint`.
