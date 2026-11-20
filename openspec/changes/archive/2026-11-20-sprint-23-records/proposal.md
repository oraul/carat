# Proposal

## Why

Sprint 23 closed with its changes merged, its sprint-end review recorded, and its plan waiting in `build/plan/` (`build/plan/sprint` names `sprint-23`, `docs/sprints.tsv` ended at `sprint-22`): the backlog grooming, the two lane queues of sprint 24, and the findings files of its deliveries are still unfolded. It is applied once, by its records change `sprint-23-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work before the next sprint starts. It is outside the roadmap of `docs/architecture.md` section 12: delivery records, T0, outside the sprint count.

## What Changes

- `sh tools/run_state.sh history sprint-23-records` appends the pending history row of `picker-styles-b` to `docs/metrics-feature.tsv` and of `syntax-tidy` to `docs/metrics-backlog.tsv`.
- `sh tools/run_state.sh groom sprint-23-records` applies the sprint-23 plan: grooms 16 headings, folds the 6 findings files under `docs/findings/` into `docs/backlog.md` and removes them, copies the sprint plan's two lane queues over `docs/queue-feature.md` and `docs/queue-backlog.md`, and appends the sprint-23 row to `docs/sprints.tsv`.

Out of scope: any code, test, tool, or spec change, and any hand edit of what `groom` writes.

Assumptions:

- The queues are the planner's output, applied as they stand.

## Capabilities

### New Capabilities

None: the change commits planning records only and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `docs/backlog.md`, `docs/findings/` (findings files folded and removed), `docs/metrics-feature.tsv`, `docs/metrics-backlog.tsv`, `docs/queue-feature.md`, `docs/queue-backlog.md`, `docs/sprints.tsv`.
- README.md: unchanged, no behavior or command changes.
- docs/architecture.md: unchanged, no layer, port, or roadmap item changes.
- CLAUDE.md: unchanged, no agent, workflow, command, or gate changes.
- docs/codebase-map.md: unchanged, no mapped file is added, moved, or removed (the findings files are records, not mapped).
