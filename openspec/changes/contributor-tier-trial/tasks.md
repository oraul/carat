# Tasks

## 1. The contributor's tier

- [x] 1.1 `.claude/agents/contributor.md`: the mid tier's alias as its frontmatter `model:` line, two wording trims keeping it within its budget. Verified by `make docs-lint` (budgets) and `make gates` (the scanner allows only the frontmatter line).
- [x] 1.2 `.claude/workflows/deliver-change.js`: the `agent` label in the calibration comment, `CALIBRATION` (the contributor at `agent/session`), `restoreCalibration`, and the metric line's filter. Tested in `tools/tools_test.sh` by "calibration: every kind of start has a profile", "calibration: the agent tier is the agent files' model lines", "calibration: the contributor runs on its agent file's tier at the session's effort", "calibration: the planner, quality, security, and close starts keep the session's tier", "workflow: calibrate passes a low effort and records the profile", "workflow: the metric line carries the profiles", and "workflow: a restart restores the recorded profiles of the kinds not used yet"; `make tools-test` passes.

## 2. Docs and records

- [x] 2.1 `docs/goals.md`, Calibration: the `agent` label, older rows' `cheap`, and the trial with its revert rule; `README.md`: the pipeline paragraph. Verified by `make docs-lint`.
- [x] 2.2 `docs/findings/contributor-tier-trial.md`: the plan's `tier-price-mid` finding appended with `>>`. Verified by reading the appended entry.
- [x] 2.3 Self-check: `make gates` and `make spec-validate` pass.

## 3. Review advisories, fixed in place

- [x] 3.1 `design.md`, Goals: narrow the no-cheap-label goal to the calibration profile (`CALIBRATION`, `calib.KIND`, the history's `calibration` column), naming the token labels `tools/run_state.sh` still writes as `cheap` (`metric.start.N`, `weighted_phases`) as the queued `tier-price-mid` change's; that file's fix is outside this change and recorded in `docs/findings/contributor-tier-trial.md`. Verified by `make spec-validate`.
- [x] 3.2 `docs/goals.md`, the trial's keep rule: all four figures read from the metrics history (`quality` in `first_pass`, `rework`, the rows with `ci:0` in `first_pass` for the CI fixes, `total_tokens`), none from the ignored run states. Verified by `make docs-lint`.
- [x] 3.3 `tools/tools_test.sh`: the session-tier check relabelled "calibration: the planner, quality, security, and close starts keep the session's tier", kept beside the agent-file comparison since it pins the user's decision even if one of those agent files gains a `model:` line. Verified by `make tools-test`.
- [x] 3.4 `design.md`, Migration Plan, and `docs/goals.md`: the revert also drops the tools-test check "calibration: the contributor runs on its agent file's tier at the session's effort". Verified by `make docs-lint` and `make spec-validate`.
