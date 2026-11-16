chore(pipeline): split the queue and metrics into feature and backlog lanes

## Summary

Splits the delivery records into two lanes, a feature lane and a backlog lane, each with its own queue and metrics history, and has every change write the findings it is handed to its own findings file that the sprint grooming folds into the backlog. Changes in flight conflicted on the one queue, the one metrics history, and the end of the backlog, so two branches could not package without a merge conflict; this redelivers backlog-lane-a, whose resumed review past its push raised blocking missing tests no fix push could answer.

---

## Changes

- Split docs/queue.md into docs/queue-feature.md and docs/queue-backlog.md and docs/metrics.tsv into docs/metrics-feature.tsv and docs/metrics-backlog.tsv, carrying every existing row, with the lane of a change recorded by the file its row goes to and a subject of no known type falling back to the feature lane as the proposal says.
- Change tools/run_state.sh so history, status, groom, review-due, plan-needed, and bench read both lanes, order the histories by main's merge order, strip each lane file's header at BASE, and keep queue_at's docs/queue.md fallback only for commits before the split.
- Change the package step to create docs/findings before appending the findings it is handed to docs/findings/CHANGE.md, which groom folds into docs/backlog.md at the sprint's end.
- Change the sprint shape to three features and two backlog changes, a pipeline change only for a defect, with the pipeline limit counted once per sprint across both lanes.
- Change tools/rules.sh RECORDS_RE to name the lane files and docs/findings, and narrow the docs-lint RETIRED path exemption to the records that keep history.
- Add tools-test cases for the RETIRED exemption, queue_at's fallback for an estimate and a beyond-the-sprint item, the records scope of the findings and lane files, the one-row BASE case, a subject of no known type, the cross-lane pipeline limit, and a fold of two changes' findings into the backlog.
- Document the contributor's conflict rules for a push: keep both sides of appended files, regenerate generated files with their make targets, stop and name a conflict where both sides changed the same logic.
- Document the lanes in CLAUDE.md, README.md, docs/goals.md, docs/codebase-map.md, and the agents, restoring the ci-stages and tokens command descriptions and naming the benchmark among the other agents' phases.
- Record sprint-9's last metrics row, the planner's Sprint 10 queue, and the sprint-9 grooming.

---

## Testing

- Run the security review of the committed diff at dfeb09da7597, pass with no high, medium, or low finding.
- Run the quality review at dfeb09da7597, pass with no blocking finding and three advisories, and the benchmark review, pass.
- Run the checker's stages at dfeb09da7597 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run make spec-validate after the archive, 53 passed and 0 failed.
- Run make docs-lint and make gates after packaging, both pass.

---

## Notes

Pull request 152 (backlog-lane-a) is replaced by this change and closed separately. Main's merge gate reads main's tools/rules.sh, whose RECORDS_RE lacks the lane files, so the records commit may read as code to it once. The stale row marker of spinel-update, which pointed at the unmerged backlog-lane-a branch, was cleared through tools/run_state.sh set so its row lands here. The backlog lane's own calibration (budgets, call caps, tiers, scout and benchmark rules) is judged after about five backlog runs from docs/metrics-backlog.tsv, comparing their total tokens, wall minutes, and first-pass rates with the feature lane's, and a separate workflow is proposed only if its phases turn out to differ.
