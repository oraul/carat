fix(sprint): hold sprints missing a security review, record findings

## Summary

Holds a sprint whose security review is partial or not-run, or whose whole-tree sweep failed to start, so the planner does not plan it and neither groom nor review-due closes it, and records each sprint security finding from the security reviewer's own result. Before this, a missed or partial review could still close a sprint and the review never ran again, a capped skeptic left a blocking security finding unrecorded, and the report showed a partial review like a complete one. This is part a of the queue's split `sprint-security` item, the security Medium (7); its Lows go to `sprint-security-b`.

---

## Changes

- Change `sprint_reviewed` in `tools/run_state.sh` so that in an even sprint a sweep with no run state or a not-run periodic security review holds groom and keeps review-due due, while a partial sweep is accepted.
- Change `.claude/workflows/sprint-planning.js` to record the sweep as not-run when it fails to start, and to start the planner only when the sprint security review is complete, its findings are recorded, the skeptic returned, and an even sprint's sweep ran.
- Add a Notes step that records every security finding of the reviewer's merged result in the sprint's run state, each word shell-quoted, before the skeptic, which now records only the findings it disputes and what both missed.
- Change the report's Security line to name a partial review and the files it left, and the Sweep line to point to running /sprint again.
- Add tools-test cases for both refusals, a partial sweep accepted, the report naming a partial review, the findings recorded verbatim with no skeptic, and the planner's start condition.
- Document who records what in the security and quality reviewer agents, the README's sprint planning paragraph, and the code map's sprint flow.
- Add `sprint-security-b` to the backlog pool for the two Lows and the fixed-check advisory, and record the plan, the metrics history row, and the non-blocking findings.

---

## Testing

- Run the security review of the committed diff, pass with high 0, medium 0, low 1, nothing blocking; the Low (4) is recorded in the change's findings file.
- Run the quality review, pass with nothing blocking and 6 advisories, of which 3 are recorded and 3 naming or duplication advisories are dropped.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass.
- Run the benchmark comparison against main, pass.
- Run make spec-validate after the archive, 53 passed and 0 failed.

---

## Notes

The groom refusal for a partial or not-run sprint security review already held on main, so this change adds the sweep refusal and keeps the existing behavior under test. A partial sweep does not hold the sprint, since a whole-tree review at its cap would otherwise hold every even sprint and its missed areas stay in its own run state for the planner. A disputed security finding is noted twice, once from the reviewer's result and once with the skeptic's reason. Left out for `sprint-security-b`: mergeSecurity dropping a differently spelled unreviewed file, and groom's listed and fixed checks accepting an unproven removal.
