## 1. Implementation

- [x] 1.1 Set the contributor to `agent/medium` in CALIBRATION (`.claude/workflows/deliver-change.js`), its comment naming the medium effort, and accept medium in the metric line's filter and restoreCalibration; proven by the tools-test calibration and routing cases

## 2. Tests and docs

- [x] 2.1 Tools-test (`tools/tools_test.sh`): the contributor's profile `agent/medium`, the metric line, the routing case (a normal start passes effort medium, a critical one the session's model and effort), the self-check case, and a restart restoring a medium profile
- [x] 2.2 Record the trial in `docs/goals.md` Calibration and name the medium effort in Critical changes and the README; checked by `make docs-lint`
- [x] 2.3 Add the user-approved exception line under Sprint 23 of `docs/queue-backlog.md` and drop `contributor-tier-revert` from its Pool item; checked by `make docs-lint`

## 3. Review fixes

- [x] 3.1 One `PROFILE` pattern in `.claude/workflows/deliver-change.js`, used by restoreCalibration and the metric line, and read by tools-test's calibration check with sed as CLOSABLE is (quality advisory, duplication)
- [x] 3.2 End the `contributor-tier-routing` trial line of `docs/goals.md` at this change by the user's decision of 2026-11-20, so the planner judges only the new trial (quality advisory, docs currency)
