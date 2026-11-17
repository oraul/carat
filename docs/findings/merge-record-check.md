### squash_commit falls back to HEAD, so a branch commit can pass merged_at (security Low (4))
- Location: tools/run_state.sh:1560
- Why: squash_commit falls back to HEAD and merged_on_main also accepts an ancestor of HEAD, so while origin/main has no commit whose subject ends with the pull request number, a branch commit with that subject passes merged_at; an agent could record merged at an unmerged branch commit, which would skew the history rows and the sprint base the sprint-end security review starts from.
- Fix: have squash_commit and merged_at search only BASE (origin/main), with no fallback to HEAD, so a merged value must be the squash commit on main itself; this also removes the fallback loop that can never yield an accepted commit.

### groom_row trusts history rows the branch can append after review (security Low (3))
- Location: tools/gates.sh:131
- Why: groom_row compares the appended sprints row with sprint_row, which reads the lane history rows from the working tree; those are records-only paths a branch can append to after review, so a forged history row plus a matching sprints row still passes settled_at and moves the sprint base, which groom_row is meant to prevent.
- Fix: compute the expected row from the history files at the reviewed COMMIT plus only the history row this change's own package step adds, or check that the history rows appended since COMMIT are this change's single row before trusting them.

### groom_row reads the shared sprint marker, refusing a records row merged from main (quality, behavior cost)
- Location: tools/gates.sh:128
- Why: groom_row reads the marker in the shared build/plan, so a lane that merged main's records-only sprint row after its reviews has it refused once the planner writes the next sprint's marker, and a review re-runs needlessly.
- Fix: accept a sprint row already on BASE (brought by a merge from main), or name the cost in the design's Risks.
