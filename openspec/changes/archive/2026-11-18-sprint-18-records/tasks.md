# Tasks

## 1. Planning records

- [x] 1.1 `tools/run_state.sh merge-main sprint-18-records`: take in a moved main. Checked by its output, "merged origin/main into chore/sprint-18-records".
- [x] 1.2 `tools/run_state.sh history sprint-18-records`: append the pending rows to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`. Checked by the rows of `background-default` and `groom-security-mark` in the diff, and a rerun's "history: nothing pending".
- [x] 1.3 `tools/run_state.sh groom sprint-18-records`: fold the findings into `docs/backlog.md`, copy the lane queues, append the sprint-18 row to `docs/sprints.tsv`. Checked by its output, "applied sprint-18: 4 headings groomed, 7 findings file(s) folded, its row appended to docs/sprints.tsv", and the two queues equal to `build/plan/`'s before the fixes of section 3.

## 2. Checks

- [x] 2.1 Run `make spec-validate`, `make gates`, and `make docs-lint`, all pass.

## 3. Review fixes in place

- [x] 3.1 Drop the stale "Security first" section of `docs/queue-backlog.md` and the Decisions bullet naming the merged `groom-security-mark` in both lane queues. Checked by no line of either queue naming it.
- [x] 3.2 Cite only the user's request in the feature queue's first Decisions bullet, not the "NEXT-SESSION.md" file outside the repository. Checked by no queue line naming it.
- [x] 3.3 Record in `design.md` Decisions the docs-lint hand edit of commit 1dba846 and the in-place queue fixes, the proposal's scope and assumptions matching, and add the hand edit as evidence under the backlog entry "Groom leaves references to the findings files it removes". Checked by `make docs-lint` and `make spec-validate` passing.
