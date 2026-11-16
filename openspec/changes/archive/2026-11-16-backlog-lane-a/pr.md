chore(pipeline): split the delivery records into feature and backlog lanes

## Summary

Splits the shared delivery records into a feature lane and a backlog lane: two queue files, two metrics histories, and a findings file per change that the sprint grooming folds into the backlog. Changes in flight at the same time collided on the same lines of `docs/queue.md`, `docs/metrics.tsv`, and the end of `docs/backlog.md`, so every second branch needed a hand merge of records.

---

## Changes

- Split `docs/queue.md` into `docs/queue-feature.md` and `docs/queue-backlog.md`, the planner writing both under `build/plan/` and `groom` copying each over its lane file
- Split `docs/metrics.tsv` into `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`, every existing row carried over by its squash subject, a change's lane printed by `sh tools/run_state.sh lane CHANGE`, and readers ranking both lanes in merge order by the ancestry of HEAD and origin/main
- Change the package step and `history` to write findings to `docs/findings/CHANGE.md`, which `groom` folds into `docs/backlog.md` in name order and removes, `backlog-dups` reading both
- Change the sprint shape to 3 features and 2 backlog changes, a pipeline change only for a defect, checked per lane by `make docs-lint` within the shared queue budget
- Change `exception_item` and `estimate_of` to read the lane files at a commit, and `docs/queue.md` only at commits before the split, accepting the unnumbered exception line
- Add the contributor's conflict rules: keep both sides of an appended file, regenerate a generated file with its make target, stop on a conflict where both sides changed the same logic, the fix staying in the change with checks and reviews run again
- Add tools-test cases for folding two changes' findings into the backlog, the lane of a change, the lane queues read by plan-needed and groom, and a row merged on main after the branch point
- Document the lanes in `CLAUDE.md`, the README, `docs/goals.md`, the code map, and the planner, contributor, checker, quality reviewer, and retrospective agents and commands

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass, tools-test 1321 of 1321 cases in 109 s
- Run the quality review, pass with no blocking finding after one fix round, advisories recorded as findings
- Run the benchmark review, pass with allocations unchanged
- Run make spec-validate after the archive, 53 of 53 pass, and make docs-lint and make gates after packaging, pass

---

## Notes

The backlog lane's own calibration is judged after about 5 backlog runs from `docs/metrics-backlog.tsv` against the feature lane: tokens and calls per phase against the budgets and call caps, the tiers the planner gave, how often the scout and the benchmark changed the outcome; a separate workflow follows only if the phases differ. The planner's waiting Sprint 10 plan, written as one queue, was split by item into the two lane files at packaging with no item lost or reordered within a lane. How the backlog lane picks its entries is left for backlog-lane-b in Sprint 11. Five quality advisories are recorded as findings for the next grooming.
