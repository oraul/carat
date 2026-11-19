chore(pipeline): run the contributor on the mid tier as a trial

## Summary

Runs the contributor's delivery starts on the mid tier named in its agent file, while the planner, the quality and security reviewers, the close start, and every sprint-planning start keep the session's model. The user asked for a trial of normal delivery work on the mid tier, and the calibration table's only non-session tier was labelled cheap, which would have recorded a mid-tier start as cheap.

---

## Changes

- Add the mid tier's short alias as the frontmatter model line of the contributor agent file, with two wording trims that keep it within its budget
- Change the contributor's calibration profile in the delivery workflow from session/session to agent/session, the agent file's tier at the session's effort
- Rename the calibration tier label cheap to agent, so the table, the restore of recorded profiles, and the metric line's filter no longer call a mid-tier start cheap
- Change the tools-test calibration checks to the new label, keeping the comparison with the agent files' model lines, and add checks that the contributor runs at agent/session and that the planner, quality, security, and close starts keep the session's tier
- Document the trial in docs/goals.md, Calibration: kept only if over the next 6 deliveries the history's quality first pass, rework, CI fixes, and total tokens are no worse than over the last 10 rows, otherwise reverted
- Document the trial in the README's pipeline paragraph
- Record the findings left for later in docs/findings/contributor-tier-trial.md, including the token labels and prices of tools/run_state.sh that still treat any agent-file tier as cheap
- Record the plan and the backlog lane's metrics history

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the quality review, pass with no blocking finding and two advisories recorded in the findings file
- Run the benchmark review, pass with no blocking finding
- Run make tools-test, all pass, including the new calibration checks
- Run the checker's stages (dev-build, test-build, diagnose, test-run, bench-budget, docs-lint, gates, metrics), all pass
- Run make spec-validate after archiving, 54 items pass

---

## Notes

The change takes effect at the first delivery started after the merge, whose run state records the contributor's profile as calib.contributor agent/session; older history rows keep the cheap label, which docs/goals.md reads as agent. The token weighting and labels in tools/run_state.sh are left to the queued tier-price-mid change, and tools/rules.sh is not edited since its model-line rule already allows the mid tier's alias. The revert, if the trial fails its rule, removes the model line, sets the contributor back to session/session, and drops the contributor tier check in tools-test.
