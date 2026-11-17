# Proposal

## Why

Sprint 15 closed with its six changes merged (`ci-trust-gaps`, `tab-close-c`, `ruby-structure-remove`, `motions-search-tidy`, `record-squash-commit`, `vim-folds-a`), its sprint-end review recorded, and its plan waiting in `build/plan/`: the backlog grooming, the two lane queues of sprint 16, and the findings files of its deliveries still unfolded. The plan is applied once, by its records change `sprint-15-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work before sprint 16 starts. It is outside the roadmap of `docs/architecture.md` section 12: delivery records, T0, outside the sprint count.

## What Changes

- `sh tools/run_state.sh history sprint-15-records` appends the pending history rows of both lanes: `record-squash-commit` to `docs/metrics-backlog.tsv` and `vim-folds-a` to `docs/metrics-feature.tsv`.
- `sh tools/run_state.sh groom sprint-15-records` applies the sprint-15 plan: removes the 18 headings of `build/plan/groom.txt` (16 listed by merged items: 2 by `tab-close-c`, 7 by `ruby-structure-remove`, 2 by `ci-trust-gaps`, 5 by `motions-search-tidy`; 2 duplicates) from `docs/backlog.md`, folds the seven findings files under `docs/findings/` into it and removes them, appends `build/plan/groomed.md`, copies the sprint plan's two lane queues over `docs/queue-feature.md` and `docs/queue-backlog.md`, and appends the sprint-15 row to `docs/sprints.tsv`.

Out of scope: any code, test, tool, or spec change, and any hand edit of what `groom` writes (none was needed: `make docs-lint` passes on its output).

Assumptions:

- The sprint plan was written after the sprint's last merge (#191), so its queues name no merged item as work and need no hand edit; no delivery planner plan exists for this change, so the package step's `plan-apply` leaves the copied queues as they are.

## Capabilities

### New Capabilities

None: the change commits planning records only and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `docs/backlog.md`, `docs/findings/` (seven files folded and removed), `docs/metrics-feature.tsv`, `docs/metrics-backlog.tsv`, `docs/queue-feature.md`, `docs/queue-backlog.md`, `docs/sprints.tsv`.
- README.md: unchanged, no behavior or command changes.
- docs/architecture.md: unchanged, no layer, port, or roadmap item changes.
- CLAUDE.md: unchanged, no agent, workflow, command, or gate changes.
- docs/codebase-map.md: unchanged, no mapped file is added, moved, or removed (the findings files are records, not mapped).
