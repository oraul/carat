# Proposal

## Why

Sprint 20 closed with its changes merged and its plan waiting in `build/plan/`: the backlog grooming, the two lane queues of sprint 21, and the findings files of its deliveries still unfolded. It is applied once, by its records change `sprint-20-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work. It is delivery records, T0, outside the roadmap of `docs/architecture.md` section 12.

## What Changes

- `sh tools/run_state.sh history sprint-20-records` appends the pending history rows (`contributor-tier-routing` and `finder-grep`) to the metrics files.
- `sh tools/run_state.sh groom sprint-20-records` removes the groomed headings, folds the findings files into `docs/backlog.md` and removes them, copies the two lane queues, and appends the sprint-20 row to `docs/sprints.tsv`.

Out of scope: any code, test, tool, or spec change, and any hand edit of what `groom` writes.

Assumptions: the queues are the planner's revision, applied as they stand.

- README.md: unchanged, records only

## Capabilities

### New Capabilities

None: planning records only (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`docs/backlog.md`, `docs/findings/`, `docs/metrics-*.tsv`, `docs/queue-*.md`, `docs/sprints.tsv`.
