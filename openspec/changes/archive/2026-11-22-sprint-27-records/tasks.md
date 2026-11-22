# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-27-records`: take in a moved main. Checked by its output, "holds origin/main".
- [x] 1.2 `tools/run_state.sh history sprint-27-records`: append the pending rows to the metrics files. Checked by the rows in the diff.
- [x] 1.3 `tools/run_state.sh groom sprint-27-records`: file the findings, copy the queues, append the sprint row. Checked by its output, "applied sprint-27".

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.


## 3. Review findings

- [x] 3.1 `make docs-lint` failed on seven Pool items of `docs/queue-feature.md` the plan wrote without the word "estimated" before their size; the word is added to each (no other change to the queue), so the queue passes the lint. The planner's cause (it writes a size without the word) is outside this change's files.
