chore(agents): return the contributor to high effort

## Summary

Moves the contributor's calibration back to its agent file's tier at high effort, ending the medium-effort trial early by the user's decision of 2026-11-21. The two runs at medium effort dropped procedural steps late in the run: #262 skipped its self-review rule and hand-edited snapshots, costing a fix round, and #265 returned a placeholder head and escalated to the session's model, paying for both starts.

---

## Changes

- Change the contributor's entry in the delivery workflow's calibration from agent/medium to agent/high, keeping medium an allowed effort
- Change the tools-test calibration, routing, metric line, and self-check cases to expect agent/high for a normal contributor start, a critical or escalated one still taking the session's model and effort
- Add a tools-test case that a one-line exception paragraph leaves out of the sprint count the changes it names in backticks before "run", while a bare name stays counted
- Document the trial's end and its reasons under Calibration in docs/goals.md, and say the critical-change rule falls back to high effort
- Document in the README that the contributor runs on the mid tier at high effort by the user's decision
- Add the user-approved exception line for contributor-tier-high and contributor-harness under Sprint 25 of the backlog queue, with the planner's queue and the metrics history row of groom-evidence-only
- Add the archived OpenSpec change and this change's findings file

---

## Testing

- Run the security review of the committed diff, pass with 0 High, 0 Medium, and 0 Low findings
- Run the quality review, which blocked once on the exception line naming its changes without backticks; fixed with a tools-test case, then pass with 0 blocking and 0 advisory
- Run the checker's stages at the reviewed head (docs-lint, dev-build, test-build, diagnose, test-run, gates, tools-test, bench-budget, metrics), all pass
- Run the benchmark review, pass with allocations and rounds unchanged
- Run make gates, make docs-lint, and make spec-validate after packaging, all pass

---

## Notes

The change is critical by rule b, an edit of the delivery workflow, so its contributor ran on the session's model. Large-estimate, critical, and escalated runs keep the session's model as before; tools/rules.sh is untouched.
