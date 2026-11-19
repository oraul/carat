chore(pipeline): route contributor tier and effort by critical change

## Summary

Routes the contributor's model and effort per run: normal runs use the agent file's mid tier at a new high effort, and critical runs use the session's model at the session's effort. The user asked for the mid tier at high effort by default and for the session's model where the change touches the guards, the toolchain, or the editor's untrusted-input code, and for a failing run to stop retrying on the weaker tier.

---

## Changes

- Add a high effort to the workflow's calibration and set the contributor to the mid tier at high effort, accepted by the metric line and the restart restore.
- Add a critical field to the planner's result and the queue item, naming a rule letter and a path; a critical run, or one estimated large, runs its contributor starts on the session's model, recorded as a metric.
- Add an escalation after a self-check mismatch, a non-result, or a second blocking quality round: the run's later contributor starts use the session's model, noted and recorded as a metric.
- Restore the critical, escalated, and blocking-round routing state when a run resumes.
- Document the critical rules and the escalation in docs/goals.md, count the new profile in its Calibration note, and name the field in the planner's agent file and the README.
- Extend tools/tools_test.sh with cases for the high effort, a critical run, the escalation, the restore, and the metric, and list the new metrics in the run state header.

---

## Testing

- Run make gates, pass.
- Run make spec-validate, 54 passed, 0 failed.
- Run the checker's stages (diagnose, dev-build, test-build, test-run, bench-budget, tools-test, docs-lint, gates), all pass at the reviewed commit.
- Security review of the committed diff, pass with no findings.
- Quality review, pass with no blocking findings.
- Benchmark review, pass.

---

## Notes

This change edits the workflow and the agent files, so it is critical by its own rule, but the routing is not live until it merges and its own run used the earlier settings. tools/rules.sh is not edited. Non-blocking advisories, among them untested escalation triggers and a loose critical match in the queue line, are recorded in docs/findings/contributor-tier-routing.md.
