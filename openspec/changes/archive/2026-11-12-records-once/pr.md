fix(pipeline): apply the planning records once

## Summary

Makes the planning records a package step commits apply once: groom applies a sprint plan only when its row is not yet recorded and retires the plan's marker, history adds no metrics row a run already has, and a brief can exclude history and groom from a change's package step. Pull request 111 ran both although its brief excluded them and left the sprint-1 marker behind, so the next package step would have applied the same plan again, and the records-only path list stood in three drifting copies while any edit of docs/sprints.tsv could shrink the sprint-end security review.

---

## Changes

- Change groom to do nothing and say so when docs/sprints.tsv, in the working copy or at main, already holds the marker's sprint, and to retire the marker to build/plan/sprint.applied once the plan is applied or found applied.
- Change history to skip a change whose metrics row main already holds or whose run state records an appended row, and say so.
- Add the run-state key records, set to skip from the brief's input or the planner's new optional records result field, under which history and groom for that change do nothing and the package text tells the contributor to run neither.
- Add RECORDS_RE to tools/rules.sh as the one records-only path list, docs/sprints.tsv included, read by settled_at in tools/gates.sh, TEST_ONLY in tools/run_state.sh, and documentation() in tools/ci_scope.sh.
- Fix settled_at to exempt a docs/sprints.tsv change only when it appends rows, so an edit of an earlier row no longer moves the sprint base.
- Add tools-test cases for the applied-once groom and history, the records skip, the shared path list, and the appended-rows limit.
- Document history CHANGE, groom CHANGE, and the records key in CLAUDE.md, the contributor's package step, the README, and the code map.
- Record the planner's queue, the metrics row of sprints-gate, and this change's eight quality advisories in the docs records.

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low findings
- Run the quality review, passed with no blocking findings and eight advisories, appended to docs/backlog.md
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark review, passed with no allocation or round regression
- Run make spec-validate, 51 passed and 0 failed
- Run make gates and make docs-lint after packaging, all pass

---

## Notes

This is a T0 correction outside the sprint count and alters no editor behavior, so its OpenSpec change is archived without delta specs. It applies, reverts, or regrooms no plan or row by itself; jump-motions resumes after this merge, taking main into its branch and keeping main's docs/queue.md, docs/backlog.md, docs/metrics.tsv, and docs/sprints.tsv over its own commit. The eight quality advisories, such as a missing js case for the package-text choice and the two meanings of planning records, are left in docs/backlog.md for a later change.
