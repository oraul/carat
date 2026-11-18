# Tasks

## 1. The contributor's tier

- [x] 1.1 `.claude/agents/contributor.md`: the mid tier's alias as its frontmatter `model:` line, two wording trims keeping it within its budget. Verified by `make docs-lint` (budgets) and `make gates` (the scanner allows only the frontmatter line).
- [x] 1.2 `.claude/workflows/deliver-change.js`: the `agent` label in the calibration comment, `CALIBRATION` (the contributor at `agent/session`), `restoreCalibration`, and the metric line's filter. Tested in `tools/tools_test.sh` by "calibration: every kind of start has a profile", "calibration: the agent tier is the agent files' model lines", "calibration: the contributor runs on its agent file's tier at the session's effort", "calibration: the judgment starts but the contributor keep the session's tier", "workflow: calibrate passes a low effort and records the profile", "workflow: the metric line carries the profiles", and "workflow: a restart restores the recorded profiles of the kinds not used yet"; `make tools-test` passes.

## 2. Docs and records

- [x] 2.1 `docs/goals.md`, Calibration: the `agent` label, older rows' `cheap`, and the trial with its revert rule; `README.md`: the pipeline paragraph. Verified by `make docs-lint`.
- [x] 2.2 `docs/findings/contributor-tier-trial.md`: the plan's `tier-price-mid` finding appended with `>>`. Verified by reading the appended entry.
- [x] 2.3 Self-check: `make gates` and `make spec-validate` pass.
