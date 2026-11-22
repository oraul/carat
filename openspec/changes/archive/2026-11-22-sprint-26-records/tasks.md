# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-26-records`: take in a moved main. Checked by its output, "holds origin/main".
- [x] 1.2 `tools/run_state.sh history sprint-26-records`: append the pending rows to the metrics files. Checked by the rows in the diff.
- [x] 1.3 `tools/run_state.sh groom sprint-26-records`: file the findings, copy the queues, append the sprint row. Checked by its output, "applied sprint-26".

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.

## 3. Review findings

- [x] 3.1 Security Low: the sprint-26 Groom line of `docs/queue-backlog.md` cites the fixing commit (9e4aca0, #289) of the four security Low entries groom removed, as "sec 9e4aca0" within the lane budget. Fixed in the line; making groom itself require a fixing commit for a security entry needs new code in `tools/run_state.sh`, outside this change's files, so it stays recorded in `docs/findings/sprint-26-records.md`.
