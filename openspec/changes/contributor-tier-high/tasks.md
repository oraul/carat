## 1. Implementation

- [x] 1.1 Set the contributor back to `agent/high` in CALIBRATION (`.claude/workflows/deliver-change.js`), medium staying in PROFILE; proven by the tools-test calibration and routing cases

## 2. Tests and docs

- [x] 2.1 Tools-test (`tools/tools_test.sh`): the contributor's profile `agent/high`, the metric line, the routing case (a normal start passes effort high, a critical or escalated one the session's model and effort), and the self-check case; the restart case keeps a medium profile
- [ ] 2.2 Record the trial's end in `docs/goals.md` Calibration and name the high effort in Critical changes and the README; checked by `make docs-lint`
- [ ] 2.3 Add the user-approved exception line under Sprint 25 of `docs/queue-backlog.md`; checked by `make docs-lint`
