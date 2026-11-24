chore(planner): follow the user's decision before its own rules

## Summary

The planner now follows the user's decision as its first rule: whatever a brief's USER DECISIONS or the user's recorded request says about one delivery, a split, the items, their order, or a sprint's contents is kept as written. A recent run split a delivery the user had decided was one, because the planner's size check ran before anything the user said.

---

## Changes

- Add a first rule to the planner agent, ahead of the rubric and the size check, that follows the user's decision and records that it overrode the planner's own rule, with the rule number, where the planner would have decided otherwise.
- Change the delivery workflow's planner start to carry the rule and the brief's USER DECISIONS before the plan request, and validate the plan so a split of a brief whose USER DECISIONS says one delivery or no split stops the run unless the override is recorded.
- Change the sprint workflow's planner start to carry the same rule right after its mode line.
- Change the rubric in docs/goals.md so the size check and the sprint rule apply only where the user decided nothing.
- Document the rule in the brief standard, the README pipeline step, and the CLAUDE.md planner bullet, shortening two sentences there to stay within its size budget.
- Add tools-test cases that fail before and pass after for the agent file, CLAUDE.md, both planner prompts, and the plan validation.
- Record the archived OpenSpec change, the metrics history rows, and the next backlog queue.

---

## Testing

- Run the security review of the committed diff, no findings at any severity, nothing blocking
- Run the benchmark review, pass with no blocking finding
- Run the check stages at the reviewed head (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run spec-validate after the archive, 56 of 56 pass

---

## Notes

The change is delivered with skip_specs because no behavior spec moves. The two docs, goals.md and brief-standard.md, are not pinned by a test, since the rules file that lists pinned documents must be edited first and alone; this is recorded in the change's findings file. On a resume the planner prompt has no USER DECISIONS text, so only the rule applies there, not the plan validation. The sprint size, early close, and extension options are left out as the user stopped them.
