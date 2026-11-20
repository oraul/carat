chore(workflow): run the contributor at medium effort

## Summary

Moves the contributor's calibration from the mid tier at high effort to the mid tier at medium effort, while critical, large-estimate, and escalated contributor starts keep the session's model and effort. The user decided on 2026-11-20 to trial a cheaper effort for normal contributor starts, and docs/goals.md records how the trial is judged and when it is reverted.

---

## Changes

- Change the contributor's entry in CALIBRATION of the delivery workflow to agent/medium, its comment now naming the allowed efforts low, medium, high, and session
- Add one PROFILE pattern in the delivery workflow that accepts the medium effort, used by restoreCalibration and by the metric line's filter, which now splits each pair once and tests its value against the word pattern or PROFILE
- Change the tools-test calibration, metric line, routing, and self-check cases to expect agent/medium, the edited routing case proving a normal contributor start passes effort medium while a critical one gets the session's model and effort, extend the restart case to restore a recorded medium profile, and add one case that reads PROFILE, which the calibration completeness check now uses
- Document the trial in docs/goals.md Calibration, comparing the next 6 non-critical deliveries with rows 233 to 250 and 224 to 229 and reverting to high effort if the quality first pass or the rework gets worse, and end the earlier contributor-tier-routing trial there
- Document the medium effort in docs/goals.md Critical changes and in the README's pipeline description
- Add the user-approved exception line under Sprint 23 of docs/queue-backlog.md and drop contributor-tier-revert from its Pool, with the planner's queue for this lane and the backlog lane's metrics history row
- Archive the OpenSpec change with skipped specs, since no behavior spec changes

---

## Testing

- Run the security review on the committed diff, pass with no high, medium, or low findings
- Run the quality review, pass with no blocking findings and no advisories left
- Run the benchmark review, pass
- Run the checker's stages diagnose, dev-build, test-build, test-run, bench-budget, tools-test, docs-lint, gates, and metrics, all pass
- Run make spec-validate after the archive, 54 passed and 0 failed

---

## Notes

The change edits the delivery workflow, so it is critical by rule b and its own contributor ran on the session's model. It does not touch tools/rules.sh or any file of the feature lane.
