## 1. Implementation

- [x] 1.1 Set the contributor back to `agent/high` in CALIBRATION (`.claude/workflows/deliver-change.js`), medium staying in PROFILE; proven by the tools-test calibration and routing cases

## 2. Tests and docs

- [x] 2.1 Tools-test (`tools/tools_test.sh`): the contributor's profile `agent/high`, the metric line, the routing case (a normal start passes effort high, a critical or escalated one the session's model and effort), and the self-check case; the restart case keeps a medium profile
- [x] 2.2 Record the trial's end in `docs/goals.md` Calibration and name the high effort in Critical changes and the README; checked by `make docs-lint`
- [x] 2.3 Add the user-approved exception line under Sprint 25 of `docs/queue-backlog.md`; checked by `make docs-lint`

## 3. Review fixes

- [x] 3.1 Write the Sprint 25 exception line's names in backticks (`docs/queue-backlog.md`), so queue_class puts `contributor-tier-high` and `contributor-harness` outside the 3; proven by the tools-test case that a one-line exception paragraph puts out the changes it names in backticks before run, not a bare name
- [x] 3.2 Say in tools-test's calibration comment that the contributor runs on its agent file's tier at high effort by the user's decision, no trial open
- [x] 3.3 End the routing trial line of `docs/goals.md` Calibration at its close, no trial left for the planner to judge
- [x] 3.4 Leave the groom-evidence-only line as the one example in the exception paragraph finding (`docs/findings/contributor-tier-high.md`), the Sprint 25 line now naming its changes in backticks; checked by `make docs-lint`
