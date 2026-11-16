# Proposal

## Why

Sprint 8's review found three ways a sprint's security review is skipped or misses a diff (`docs/queue.md` item 1 of sprint 9, T1 pipeline security). A periodic security review (`/review`'s `review-DATE`, sprint-planning's `sprint-N`) records `review.periodic-security` on its own run state, but `plan-needed` (`tools/run_state.sh:1712`) reads only the notes of pending merged changes, so a delivery of the queue head prints `not needed:`, the workflow skips the planner (`planSkipped`, `.claude/workflows/deliver-change.js:996`), and the security-first stop never runs: Medium (5). `review-due` leaves every change marked `beyond the sprint` out of the count with no bound (`tools/run_state.sh:1507`), so a queue that marks every item never closes a sprint: Medium (4). `sprint_row` (`tools/run_state.sh:1583`) takes an exception's row that comes after the fifth counted one, so the next sprint's combined diff starts past that change and no sprint review reads it. The exception loop (`tools/run_state.sh:1492`) reads as a double negative.

## What Changes

- `plan-needed` prints `needed:` when a `review-*` or `sprint-*` run state records a failing periodic security review (`blocked`, or any result whose summary counts `blocking=` above zero) and no change merged after the commit it reviewed (the newest history row's merged commit or a pending change's does not descend from it), so the planner runs and its security-first stop applies. A merge after the review clears it: that delivery's planner saw the finding, as plan-needed named it, and either delivered its fix first or judged it not blocking.
- `review-due`, `groom`, and the sprint row leave out of a sprint's count at most `SPRINT_EXCEPTIONS` (1) changes marked `beyond the sprint`, the first in merge-row order; a later marked change counts, so a sprint closes after at most six merges whatever the markers say.
- The sprint row ends at the fifth counted change: an exception's row after it goes to the next sprint, whose combined diff starts at the fifth counted change's merge and so covers it.
- The exception loop reads as a plain `if`, and stops reading queues once the cap is reached.
- Cases in `tools/tools_test.sh` prove each, and the existing groomed-row case states the corrected row.
- Docs: the README pipeline section (the sprint count and the planner trigger) and the map's `tools/run_state.sh` entry.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/tools_test.sh`, a comment in `.claude/workflows/deliver-change.js`.
- README.md: changed, the sprint count's cap and the planner's trigger.
- CLAUDE.md: unchanged, its planner line (it runs only when `plan-needed` finds a decision, an unresolved blocking security finding stopping the run) and its Sprints line still hold; the cap lives in `tools/run_state.sh`, the README, and the map.
- docs/architecture.md: unchanged, it does not describe the planner trigger or the sprint count.
- docs/codebase-map.md: changed, the `tools/run_state.sh` entry names the new helper and constant; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline security fix (T1) of sprint 9. One reviewable pull request, not split.

Backlog headings this change covers, from its queue entry: "### Sprint count exemption trusts model-written queue text", "### sprint_row takes exception rows past the fifth counted row", "### Double negative in the sprint exception count".

Minor assumptions: the cap is one exception per sprint (sprint 9 holds one, `spinel-notice`, so the cap allows it), the first marked change in the sprint's merge-row order taking it; "no later merge fixed" is read mechanically as "no change merged after the reviewed commit", since a merge after it passed a planner that saw the finding; a `partial` or `not-run` result without blocking findings is not failing, as it has nothing for the planner to place; the double negative has no behavior to test, so its proof is the unchanged review-due cases; tools-test time is held by reading the review runs without a subprocess per file, the cap's early exit from the queue reads, and a later-merge case that reuses an existing history row: three runs each measured 99.9 s on the branch against 100.7 s on main.

## Out of scope

- Ordering history rows by merge order (they follow the run states' order), and rewriting existing rows of `docs/metrics.tsv` or `docs/sprints.tsv`.
- Reading the reviewers' `security` notes on review run states, and any change to what the planner does once it runs.
- Validating the queue text itself (the planner writes the markers).
