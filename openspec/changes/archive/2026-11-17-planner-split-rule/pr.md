chore(planner): split briefs of three or more parts and apply the lanes wording

## Summary

Makes the planner split a brief of three or more independently testable parts or map areas into balanced changes, size one step up after two overruns of comparable rows of its lane, and propose the split of what a round-limit stop left, and applies the user-approved CLAUDE.md wording for parallel lanes. Four-part briefs ran whole and overran (#166 with four fixes used 3 of 3 rework rounds with quality first pass 0, and the T1 rows of the last 10 backlog rows used 9 rework rounds over 5 changes), while CLAUDE.md still described a single-lane pipeline.

---

## Changes

- Change the planner's size check in .claude/agents/planner.md step 3 to the three-part or three-area split, the size-up after two overruns, and the round-limit split in notes, tightening other wording so the file stays at 8,189 of 8,192 bytes with no other rule changed
- Change the CLAUDE.md Agents section to the parallel-lanes wording drafted in the archived parallel-lanes-b design and approved verbatim by the user, replacing the contributor, planner, Sprints, Backlog, and Run state bullets, adding a Lanes bullet, and shortening the Commands run state bullet as drafted, at 30,714 of 30,720 bytes
- Add tools-test cases asserting the planner's split rule text and the CLAUDE.md Lanes bullet
- Document the new size check in the README's planner step
- Move planner-split-rule from the backlog pool to a user-approved exception line under Sprint 12, so the sprint does not count it, and append the windows-buffers-tidy metrics row
- Record three non-blocking documentation drift findings in docs/findings/planner-split-rule.md

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and 4 advisories
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run make spec-validate after the archive, 53 of 53 pass

---

## Notes

The CLAUDE.md wording was approved verbatim by the user, so it is applied line for line, including the shorter Commands run state bullet; the split rule did not fit CLAUDE.md's budget and lives in planner.md and the README only. docs/goals.md keeps its older split threshold until the planner is next asked to rewrite it, recorded as a finding. Of the quality advisories, the one on the wording of planner.md step 3 ("the last two" without a noun) is dropped as a minor wording note; the goals.md threshold, the planner.md step 5 plan-apply drift, and the CLAUDE.md build/plan path are recorded as findings. This change is Sprint 12's user-approved pipeline exception, delivered beyond the sprint in the backlog lane.
