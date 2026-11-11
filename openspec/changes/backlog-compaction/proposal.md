# Proposal

## Why

`docs/backlog.md` is 431,045 bytes in 681 entries, and the same finding is entered two or three times: each delivery's package step adds the findings it is handed, and the planner and the reviewers read the file to place or avoid them, so the file grows by repetition and every delivery pays to read it. The user aborted `backlog-split` (dividing the file by kind) and decided instead to merge the duplicates once now and to make the file append-only during deliveries, leaving its upkeep to the periodic review. This change is outside the roadmap of `docs/architecture.md` section 12: it is delivery process and records.

## What Changes

- Merge every set of `docs/backlog.md` entries that record the same finding into one entry that keeps each merged entry's locations, why, and fix outline (as a `Raised again` bullet, the style the file already uses); where the duplicate is one clause of a grouped entry, the clause moves to the standalone entry and the rest of the grouped entry stays.
- State the append-only rule: during a delivery no agent reads `docs/backlog.md` whole (a contributor or scout whose queue item names backlog entries, as the queue folds findings into it and its batch items are only entries, greps the file for those entries alone); the contributor appends the non-blocking findings it is handed, and the planner's `build/plan/backlog.md`, to the end of the file by a shell append without reading it, and never removes an entry, even one its change fixes; the planner takes new findings from the run states' notes and the queue; removing fixed or gone-code entries, merging duplicates, and turning entries into queue items belong to the periodic review (its backlog step is queue item `periodic-council`).
- The rule is written in CLAUDE.md (the Agents section and the coding-conventions line), the agent files that name the backlog (contributor, planner, quality reviewer, security reviewer, retrospective), the prompts of `.claude/workflows/deliver-change.js`, the `/plan` and `/review` commands, and the README's process steps.

Out of scope: a byte budget for the backlog and any enforcement in `tools/agent_guard.sh` (the brief excludes both); dropping stale or fixed entries, changing owners, or rewording entries beyond the merge; the periodic review's backlog step, its own workflow, and the two-change cadence (queue item `periodic-council`); `reading-rules`. The queue's bookkeeping (item 1 replaced, `backlog-split` aborted, items 2 and 5) is the planner's `build/plan/queue.md`, copied in the package step.

Assumptions:

- The brief's count of nine duplicate sets was made earlier; every set found that records the same finding is merged, and the entries that themselves report duplicates (`Backlog entries are duplicated`, `Backlog duplicates found at #96`, `Three backlog findings are entered twice`) stay, since the brief forbids dropping fixed entries; the periodic backlog step removes them.
- The periodic quality review keeps reading the backlog for entries already fixed, duplicated, or naming gone code: it is the periodic review, where the brief moves that work, and it never runs as a delivery phase's reviewer.
- `docs/goals.md` names no backlog read, so it is unchanged; `tools/gates.sh` and `tools/run_state.sh` only list the file among the paths a package commit may touch, which stays true.

## Capabilities

### New Capabilities

None: the change is delivery process and records and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `docs/backlog.md`, `.claude/agents/contributor.md`, `planner.md`, `quality-reviewer.md`, `security-reviewer.md`, `retrospective.md`, `.claude/workflows/deliver-change.js`, `.claude/commands/plan.md`, `.claude/commands/review.md`.
- CLAUDE.md: changed, the Agents section and the coding-conventions line state the append-only rule.
- README.md: changed, the planner step no longer reads the backlog and the package step appends to it.
- docs/architecture.md: unchanged, it names the backlog only as where two plugin API requests are recorded, not how it is kept.
- docs/goals.md: unchanged, it names no backlog read.
