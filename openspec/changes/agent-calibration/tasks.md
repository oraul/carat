# Tasks

## 1. The calibration table

- [x] 1.1 `.claude/workflows/deliver-change.js`: `CALIBRATION`, `calibrated`, and `calibrate()`, every agent start taking its options from it, the scouts at `cheap/low`. Tested by "calibration: every kind of start has a profile", "calibration: the cheap tier is the agent files' model lines", "calibration: the security reviewer keeps the session's tier and effort", and "workflow: calibrate passes a low effort and records the profile".
- [x] 1.2 `.claude/workflows/deliver-change.js`: `metricLine()` writes `calib.KIND=TIER/EFFORT`, `seed()` reads it back. Tested by "workflow: the metric line carries the profiles".

## 2. The history column

- [x] 2.1 `tools/run_state.sh`: the `calibration` column in `HEADER` and `history_row`, the `metric.calib` key in the header comment. Tested by "run_state: history records the profiles" and "run_state: every history row has the header's columns".
- [x] 2.2 `docs/metrics.tsv`: the header's new column and `-` on every older row.

## 3. Docs and bookkeeping

- [x] 3.1 `docs/goals.md`: the Calibration section with the table's reasons and the keep-or-revert rule; `make docs-lint` passes.
- [x] 3.2 `docs/backlog.md`: the stopped `merge-gate-integrity` run's three findings, and its queued entries moved to `check-isolation`.
