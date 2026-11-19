# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-20-records`: take in a moved main. Checked by its output, "holds origin/main".
- [x] 1.2 `tools/run_state.sh history sprint-20-records`: append the pending rows to the metrics files. Checked by the rows in the diff.
- [x] 1.3 `tools/run_state.sh groom sprint-20-records`: fold the findings, copy the queues, append the sprint row. Checked by its output, "applied sprint-20".

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.

## 3. Review fixes

- [x] 3.1 `docs/queue-backlog.md` Calibration decision: say quality first pass 1 of 7 in sprint-20 (the `docs/sprints.tsv` figure) and 1 of 8 with finder-grep. Checked by the line in the diff.
