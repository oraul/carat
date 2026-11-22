chore(workflow): drop the scout from deliveries

## Summary

Deliveries no longer plan scout areas or start a scout: the contributor takes the locations a change edits from the plan notes, else the queue entry or the brief. The scout cost about a fifth of a delivery's output tokens and calls while the contributor redid most of its packs, and the user decided on 2026-11-22 to drop it.

---

## Changes

- Remove the Scout phase, the area plan, and their caps, calibration profiles, helpers, and prompt arguments from the delivery workflow, which now starts no scout
- Add a fixed locations line to the implement start (plan notes, else the queue entry or the brief) and ask the planner's prompt to name the locations a change edits
- Remove the scout agent file and add it to the retired paths docs-lint lets backlog entries still name
- Change the contributor, planner, and deliver command instructions and the contributor notes to read the locations instead of scout packs
- Change the read-profile guard cases of the tools tests from scout packs to build/plan, drop the scout's caps, calibration, helper, and agent-file cases, and add cases showing a delivery starts no scout and the implement start carries the locations line
- Document the pipeline without the scout in CLAUDE.md, README.md, docs/goals.md, and the tmp comment of tools/run_state.sh
- Record one quality finding not fixed, a restored run state's leftover scout calibration kind, in the change's findings file

---

## Testing

- Run the security review of the committed diff at c6cfc9bfd6e3, passed with no high, medium, or low finding
- Run the check stages at c6cfc9bfd6e3 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the benchmark review at c6cfc9bfd6e3, passed with no blocking finding
- Run the quality self-review of the diff, two findings: one fixed in place, one recorded
- Run make spec-validate after the archive, 56 passed and 0 failed

---

## Notes

The change alters no specified behavior and is archived with skip-specs. The keep-or-revert decision over the next five delivery rows is queued in docs/queue-backlog.md. A run state restored from before this change may still carry a scout calibration kind, which is harmless recorded data and left for a follow-up.
