chore(pipeline): plan deliveries in sprints with a sprint-end review

## Summary

Adds a sprint model to the delivery process: the queue becomes a sprint of five self-contained changes, and a new sprint-planning workflow, run with /sprint once the sprint's five changes have merged, reviews their combined diff, grooms the backlog, and plans the next sprint. The periodic whole-tree review ran inside nearly every pipeline delivery and cost about half of a run's tokens, and each delivery grepped the backlog because queue items only pointed to its entries.

---

## Changes

- Add the sprint-planning workflow and the /sprint command, whose phases check that the sprint is due, run the security and quality reviews of the sprint's combined diff with the whole-tree sweep every second sprint, let a skeptic weigh the findings, and have the planner groom the backlog and write the next sprint's queue
- Change review-due in tools/run_state.sh to count merges in sprints from the new docs/sprints.tsv, keeping a sprint due until its security review is recorded, and drop the review-area triggers
- Add backlog-dups and groom to tools/run_state.sh, so the next package step applies a waiting sprint plan, removes only the backlog entries the plan names, and refuses a security entry removed without a merged item or fixing commit
- Remove the periodic review from the delivery workflow, whose close now reports when sprint-planning is due, and stop every delivery agent from reading or grepping the backlog
- Change the planner to write self-contained queue items and add its sprint mode, and add the sprint and skeptic modes to the quality and security reviewers
- Add a docs-lint check that the queue's sprint section holds 0 to 5 items with at most one pipeline item
- Add tools-test cases for the sprint count, the grooming refusals, the queue check, and the agent guard rules
- Document sprints, the sprint-planning workflow, and the append-only backlog in CLAUDE.md, the README, the goals, the code map, and the agent files

---

## Testing

- Run the security review of the committed diff, pass with no blocking finding; its two Medium findings at confidence 7 and two Low findings are appended to the backlog
- Run the quality review, pass after two blocking findings were fixed in this branch; its advisories are appended to the backlog
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark review, pass with allocations and rounds unchanged
- Run make spec-validate after the archive, all 51 items pass
- Run make gates and make docs-lint before the push, both pass

---

## Notes

The first sprint plan lands through the next delivery's package step, which applies build/plan/ with groom as it already applies the planner's queue and the metrics rows. Sprint 0 in docs/sprints.tsv is the seed ending at remove-commit-hooks, so sprint 1 is backlog-compaction, delivery-speed, pr-on-push, sprint-planning, and ci-time. /review stays as the on-demand whole-tree review and is the sweep's engine. The review's non-blocking findings, among them closing a sprint whose security review did not finish, are recorded in the backlog for the next sprint.
