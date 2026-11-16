# Proposal

## Why

Three pipeline defects of sprint 8's first item (`docs/queue.md` item 1, T1). A brief that keeps the queue's order still starts the planner: #135's plan phase took 14.9% of its output tokens, and #136, a resume whose brief held the main session's decisions, spent 41,075 of 242,766 tokens (16.9%) and 20 calls on a full planner, although `plan-needed` printed `not needed:` each time; the workflow (`.claude/workflows/deliver-change.js`, the Plan phase) plans whenever the brief is more than the change's name. `history` appends a row for a run whose `merged` value names no commit on main (`authoring-kit`'s row holds `e375e4cfa5cf`, which no clone has, and its date is `-` from the fallback at `tools/run_state.sh:1365`), because `pending_list` checks only the value's shape. `review-due` counts every merge toward a sprint's five, so a change the user approved beyond the five (its queue item marked `the user-approved exception`, as `spinel-notice` is) closes the sprint one change early.

## What Changes

- The Plan phase is skipped whenever `plan-needed` prints `not needed:` (the change heads the queue and no pending change holds a note to place), whatever the brief says: a pure helper of the workflow, `planSkipped`, decides it, and the brief still reaches the scouts and the contributor. A brief for a change that is not the queue's head still plans, as `plan-needed` says `needed:`.
- `pending_list` lists a merged run only when its `merged` commit is one git knows on HEAD or on BASE (`origin/main`), so `history`, `bench`, `plan-needed`, and `review-due` never take a never-merged run; `history` names each such run it leaves out.
- `review-due` leaves out of a sprint's count a change whose item in `docs/queue.md` at the parent of its squash commit carries `user-approved exception` in its parenthesis; the not-due line names it, and the due line still lists it, so the sprint review covers its diff. `groom`'s sprint row and its history-row check count the same way, so the sprint closes where review-due says.
- Cases in `tools/tools_test.sh` prove each: a fixed-order brief skips the planner, a never-merged run gets no row, and a marked change does not count.
- Docs: the README pipeline section (the planner trigger, the sprint count) and the map's `tools/run_state.sh` entry.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `tools/run_state.sh`, `tools/tools_test.sh`.
- README.md: changed, the planner's trigger and the sprint count.
- CLAUDE.md: unchanged, its Sprints line (`/sprint` ends until `review-due` counts the sprint's fifth merge) and its planner line (it runs only when `plan-needed` finds a decision) still hold; the exception rule lives in `tools/run_state.sh`, the README, and the map, and the file is 2 bytes under its budget.
- docs/architecture.md: unchanged, it does not describe the planner trigger or the sprint count.
- docs/codebase-map.md: changed, the `tools/run_state.sh` entry names the new helpers; no file is added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline fix (T1) of sprint 8. The planner did not split it, so there is no part b.

Backlog headings this change covers, from its queue entry: none.

Minor assumptions: the marker is the words `user-approved exception` inside the item's first parenthesis (the prose of an item, such as this one's, never marks it); the brief's "history skips a never-merged row" is read with its fix outline, "history keeps unmerged rows out"; a brief that wants other queue items reordered while its change heads the queue now needs `/plan` or a sprint plan, since only `plan-needed` decides; `groom`'s sprint row follows review-due's count, since a row cut at five would put the sprint's last change into the next sprint; the existing `authoring-kit` row stays, as `history` only appends.

## Out of scope

- Removing or rewriting existing rows of `docs/metrics.tsv` or `docs/sprints.tsv`.
- Any change to what the planner does once it runs, or to the queue's order.
- Marking items in the queue: the planner writes the marker.
