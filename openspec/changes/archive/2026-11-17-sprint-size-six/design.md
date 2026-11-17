# Design

## Context

A sprint closes at `SPRINT_SIZE` counted merges (`tools/run_state.sh`): `review-due` compares `sprint_count` with it, `sprint_row` ends the sprint's row at the SPRINT_SIZE-th counted change, and `groom` refuses a sprint with fewer history rows. `sprint_state` already computes the sprint in progress, `sprint_n`, from the last row of `docs/sprints.tsv`, before each of those readers runs. The user's decision of 2026-11-17 makes a sprint 6 changes (3 features, 3 backlog changes) from sprint-17 on, for now, while sprint-16 closes at its fifth counted merge as planned.

## Decisions

### The size keyed on the sprint number

Three constants beside the others: `SPRINT_SIZE=6`, `SPRINT_SIZE_FROM=17`, and `SPRINT_SIZE_BEFORE=5`. `sprint_state` sets `sprint_size` to `SPRINT_SIZE` when `sprint_n` is at least `SPRINT_SIZE_FROM`, else `SPRINT_SIZE_BEFORE`, and every reader (`review_due`'s due test and its "K of N" line, `sprint_row`'s `size`, `groom`'s row count) reads `sprint_size`. The sprints file stays as it is: no column records a size, so the rows of sprints 0 to 15 and their readers are untouched, and a later decision changes one constant pair. Alternatives: a size column in `docs/sprints.tsv` (a format change of an appended record, for one value), or `SPRINT_SIZE=6` alone (would hold sprint-16 open past its fifth merge, against "Sprint 16 finishes as planned").

### Three backlog batches

`PICK_BATCHES` becomes 3: `backlog-pick` runs only in the planner's sprint mode, and its next run plans sprint-17. The planner's sprint mode takes the first three batches as its three backlog items.

### The docs-lint share

`check_queue` caps the backlog lane's sprint at 3 items (`backlog:3`), the feature lane at 3 as before. Sprint 16's backlog section holds at most two items and passes either way; the cap is a maximum, so a drained or shorter sprint still passes.

### What stays

`SPRINT_EXCEPTIONS=1`, `EXCEPTION_MARK`, the exception line, and the one-pipeline-item rule are unchanged. A sprint therefore closes within `sprint_size + 1` merges: six for sprint-16, seven from sprint-17.

## Tests

In `tools/tools_test.sh`, a new fixture with `docs/sprints.tsv` ending at sprint-15: sprint-16 due at its fifth counted merge; after its row, sprint-17 not due at its fifth ("5 of 6") and due at its sixth; `groom` refusing sprint-17 at five history rows and appending a row of six changes at six. A `backlog-pick` fixture of three qualifying areas prints three batches. A docs-lint case refuses a backlog sprint of four items and accepts three. The planner text check names "3 backlog items, the first three batches".

## Risks

- Sprint 16 holds two changes marked beyond the sprint (plugin-lazy-activate and this change); with `SPRINT_EXCEPTIONS=1`, the second one merged counts. This change does not alter that rule; the main session decides it (plan notes).
