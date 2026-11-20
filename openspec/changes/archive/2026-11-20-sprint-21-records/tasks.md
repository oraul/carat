# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-21-records`: take in a moved main. Checked by its output, "holds origin/main".
- [x] 1.2 `tools/run_state.sh history sprint-21-records`: append the pending rows to the metrics files. Checked by the rows in the diff.
- [x] 1.3 `tools/run_state.sh groom sprint-21-records`: fold the findings, copy the queues, append the sprint row. Checked by its output, "applied sprint-21".

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.

## 3. Review fixes in place

- [x] 3.1 Trim `docs/queue-backlog.md` to the shared queue budget and replace the backticked path of a removed findings file in `docs/backlog.md`. Checked by `make docs-lint` passing.
