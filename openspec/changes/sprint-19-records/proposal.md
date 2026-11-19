# Proposal

## Why

Sprint 19 closed with its changes merged and its plan waiting in `build/plan/`: the backlog grooming, the two lane queues of sprint 20, and the findings files of its deliveries still unfolded. It is applied once, by its records change `sprint-19-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work. It is delivery records, T0, outside the roadmap of `docs/architecture.md` section 12.

## What Changes

- `sh tools/run_state.sh history sprint-19-records` appends the pending history rows (including `contributor-tier-trial` and `match-paren`) to the metrics files.
- `sh tools/run_state.sh groom sprint-19-records` removes 6 headings, folds 5 findings files into `docs/backlog.md` and removes them, copies the two lane queues, and appends the sprint-19 row to `docs/sprints.tsv`.

- Fix two stale backticked paths in `docs/queue-feature.md` by hand (`arrange_view.rb` and `fold_handler.rb` now name their real paths), so `make docs-lint` passes; see design.md, Hand edit.

Out of scope: any code, test, tool, or spec change, and any other hand edit of what `groom` writes.

Assumptions: the queues are the planner's revision, applied as they stand but for the two paths above.

- README.md: unchanged, records only

## Capabilities

### New Capabilities

None: planning records only (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`docs/backlog.md`, `docs/findings/`, `docs/metrics-*.tsv`, `docs/queue-*.md`, `docs/sprints.tsv`.
