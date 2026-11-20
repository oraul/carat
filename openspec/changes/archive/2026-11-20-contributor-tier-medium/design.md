# Design

## Context

`calibrate(kind, opts)` reads a kind's `TIER/EFFORT` from `CALIBRATION`, passes the effort unless it is `session`, and gives the contributor the session's profile (`model: 'inherit'`, no effort) when the run is critical or escalated. Two patterns check a profile's form: the metric line's filter (`metricLine`) and the restart restore (`restoreCalibration`).

## Decisions

- One table value changes, the contributor's, from `agent/high` to `agent/medium`; the routing code stays as it is, so a critical, large-estimate, or escalated start still takes `session/session`.
- The two profile patterns and tools-test's form check add `medium` beside `low`, `high`, and `session`, so the new value is recorded, restored, and checked like the others; `high` stays allowed for a revert.
- The trial's keep rule is written in `docs/goals.md`, Calibration, with the two comparison windows the brief gives.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

A lower effort may cost first-pass quality or rework; the trial's rule reverts the contributor to `agent/high` when either gets worse over the next 6 non-critical deliveries.
