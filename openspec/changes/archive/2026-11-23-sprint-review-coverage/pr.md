chore(pipeline): continue the sprint quality review over the files it left

## Summary

The sprint close now continues its quality review over the files the planner's capped review left, instead of only counting them as not reviewed. At the Sprint 29 close 46 files (docs, tests, specs, and the tools test) were never reviewed, so the review was recorded partial with no way to finish it.

---

## Changes

- Add a continued start of the quality reviewer in the sprint close that reviews exactly the files the planner's review returned in not_reviewed, and merge its counts, notes, and remaining files into the planner's review with mergeQuality
- Change the periodic-quality record to partial while any file is still left after the continued start, also when that start returns no result, never pass
- Change the report's Quality line to name the coverage: the files the first start left, how many the continued start reviewed, and those still not reviewed
- Add a Sprint mode section to the quality reviewer agent and have the planner agent name every diff file not reviewed in not_reviewed at its cap, shortening two planner sentences to stay within its docs-lint budget
- Add tools-test cases that run the whole sprint close with each start answered from a table: a first review leaving test files gets a continued review over them, a covered one passes, files remaining or no result is partial, and nothing left starts none, plus a mergeQuality case
- Document the continued review in CLAUDE.md and README.md

---

## Testing

- Run the security review of the committed diff, no High or Medium finding
- Run the benchmark review, no blocking finding
- Run the stages of make check at the head, every stage passed including tools-test, diagnose, test-run, bench-budget, docs-lint, gates, and metrics
- Run make spec-validate after archiving the change with skip-specs, all items pass

---

## Notes

The continued start's findings arrive after the planner wrote the queue, so they are recorded as quality notes of the sprint's run state for the next sprint's planning and do not shape this sprint's queue. The change does not edit tools/rules.sh. Delivered in the backlog lane as a user request outside the sprint's three queued backlog items.
