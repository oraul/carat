# Design

## Context

`settled_at COMMIT` (`tools/gates.sh`) is true when every path changed from COMMIT to HEAD matches `^(openspec/|docs/(backlog|queue|goals)\.md$|docs/metrics\.tsv$|$)`. The security gate (security review commit), the stages gate (`phase.check`), and the passed gate (each review) call it, in the `pre-push` and `merge` groups. `groom` writes `docs/queue.md`, `docs/backlog.md`, and appends a row to `docs/sprints.tsv` (`tools/run_state.sh`, `sprint_row >> "$sprints_file"`); only the last is missing from the exemption.

## Goals / Non-Goals

Goals: a package commit written by `groom` passes the gates that hold the earlier reviews; a code change after the review still fails them. Non-goals: the stage carry and fix scope of `TEST_ONLY`, CI's documentation scope, and applying the waiting sprint plan.

## Decisions

- Add `docs/sprints.tsv` to the one regex in `settled_at`, as `docs/(metrics|sprints)\.tsv$`, rather than a second alternative, so the planning records stay one readable group. `docs-lint` does not read `docs/sprints.tsv`, and `review-due` and `groom` read it only to count and append rows, so no check that ran before the package step reads it.
- Leave `TEST_ONLY` and `ci_scope.sh` alone: neither refuses a groom write; they decide only what is carried or skipped, so the brief's "only what groom's own writes require" excludes them.
- The test sits in the `fresh security` block of `tools/tools_test.sh` after the planning-records case, where the security review is recorded at an earlier commit; the mixed case is reverted by a following commit so the later cases see the same tree.

## Risks / Trade-offs

- A records path exempt from the gates could carry content no review read. `docs/sprints.tsv` is a tab-separated data file no build, test, or tool executes; the content gate and the pull request scan still read every added line.
