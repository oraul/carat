chore(workflow): make the quality review a contributor step

## Summary

Moves the code quality review of a delivery into the contributor's own start: once every task of tasks.md is done and before the archive, the contributor reviews the whole committed diff with the quality reviewer's instructions, adds each finding as a task under a Quality review heading, and fixes it there or records it in the change's findings file with its reason. The user decided on 2026-11-21 that quality findings should become OpenSpec tasks fixed by the same contributor start rather than a separate reviewer start and rework round, while the security review stays as it is and the sprint's combined-diff quality review and skeptic remain the independent quality check.

---

## Changes

- Remove the quality reviewer phase from the delivery workflow: no quality-reviewer start on the diff, no quality rework round, carried review, first-pass verdict, or quality_blocked figure, the reviews being the security review alone, while the pull request text check by the same agent stays unchanged.
- Add the quality_review field to the contributor's result (status done and the counts added, fixed, and recorded), refuse an implement result that finished the tasks without it, each refused problem noted under its own kind and restarted once, a second refusal of a kind stopping the run, and run the archive and package step only once a quality review is recorded.
- Add the quality step to openspec/config.yaml as operations.apply.guidance and operations.archive.guidance, and make rule 10 of the contributor's card, in its agent file and the workflow's copy, this step.
- Change the merge gate's passed check in tools/gates.sh to require the check, security, and bench passes, no longer a quality review.
- Keep the security reviewer on every delivery, never skipped and blocking a High or Medium finding at confidence 8 or above, and leave sprint-planning's quality review and skeptic untouched.
- Change the tools-test cases to prove a delivery starts no quality-reviewer on its diff, a result without a quality review is refused before the archive, the security reviewer still runs and blocks, and sprint-planning still starts its quality review.
- Document the step in CLAUDE.md's Agents phases line, README.md's pipeline steps and gates paragraph, docs/goals.md, docs/contributor-notes.md, the code map's tools-test entry, the run state header, and the quality reviewer's use line.
- Record the planner's queue for the backlog lane, which adds the Sprint 25 exception line for this change and folds closing-loop-fold out of item 9, and the metrics history row.

---

## Testing

- Run the security review on the committed diff at 8045d5552c96, pass with no High, Medium, or Low finding.
- Run the checker's stages at 8045d5552c96 (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass.
- Run the quality review of the old workflow at 8045d5552c96, pass with no blocking or advisory finding, and the benchmark review, pass.
- Run make spec-validate after the archive, 55 passed and 0 failed.
- Run make gates after the archive and records commits, all gates ok.

---

## Notes

This run itself still ran the workflow loaded at its start, so its delivery had a quality reviewer phase; the new rules apply from the next delivery. Older history rows keep their quality first-pass entries and new rows carry none. Three findings beyond this change are recorded in docs/findings/review-in-openspec.md: the quality reviewer's steps 5 to 7 still describe a delivery review, the advisory-only round that settles on records-only fixes can no longer arise, and a run resumed across this change no longer hands its earlier quality advisories to the package step.
