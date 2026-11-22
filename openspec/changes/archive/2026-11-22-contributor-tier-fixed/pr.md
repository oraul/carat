chore(pipeline): keep the contributor and close starts off the session's model

## Summary

Every contributor start of the delivery workflow now runs on the contributor agent file's tier at high effort, and the close start moves off the session's model onto the same tier. This carries out the user's decision of 2026-11-22 that no contributor start uses the session's model, whatever a critical rule or an escalation says.

---

## Changes

- Change `calibrate` in the delivery workflow so the contributor's profile is always agent/high and no model override is passed, whatever `criticalRule()` or an escalation says
- Change `escalate` to note an escalation (the `escalation` note and `metric.escalated`) in a critical run too, moving no profile, so the history keeps the signal
- Keep the critical rules as labels the planner writes and the run state records as `metric.critical`, so calibration comparisons still tell critical runs apart
- Change the close start's calibration to agent/high and add a `model:` line to the retrospective agent file naming the contributor file's tier
- Add tools-test cases for a normal, a critical, a large-estimate, and an escalated contributor start at agent/high, the close start at agent/high, and the security start unchanged
- Document the decision, its dated entry, and its keep rule in docs/goals.md (Critical changes, Escalation, Calibration) and update the pipeline paragraph of README.md

---

## Testing

- Security review of the committed diff, pass, no High, Medium, or Low findings
- Run the check stages at the head (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the benchmark review, pass, no blocking findings
- Run `make spec-validate` after the archive, 56 of 56 pass

---

## Notes

The keep rule reads the next 5 rows' first passes and rework plus self_fix against the last 5 critical rows, which used the session's model; the planner queues the revert if they are worse. The change is not in the backlog queue as written: it is the user's request, the backlog lane's priority, an extra beyond Sprint 29's three by the user's exception. `tools/rules.sh` and the contributor agent file are not edited.
