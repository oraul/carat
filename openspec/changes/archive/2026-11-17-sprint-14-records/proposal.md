# Proposal

## Why

Sprint 14 closed with its five changes merged (`lsp-container-c`, `tab-close-b`, `markdown-reading-d`, `merge-record-check`, `vim-line-commands-a`), its sprint-end review recorded, and its plan waiting in `build/plan/`: the backlog grooming, the two lane queues of sprint 15, and the findings files of its deliveries still unfolded. The plan is applied once, by its records change `sprint-14-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work before sprint 15 starts. It is outside the roadmap of `docs/architecture.md` section 12: delivery records, T0, outside the sprint count.

## What Changes

- `sh tools/run_state.sh history sprint-14-records` appends the pending history rows of both lanes: `merge-record-check` to `docs/metrics-backlog.tsv` and `vim-line-commands-a` to `docs/metrics-feature.tsv`.
- `sh tools/run_state.sh groom sprint-14-records` applies the sprint-14 plan: removes the 7 headings of `build/plan/groom.txt` (all listed by merged items: 1 by `lsp-container-c`, 3 by `markdown-reading-d`, 3 by `merge-record-check`) from `docs/backlog.md`, folds the five findings files under `docs/findings/` into it and removes them, appends `build/plan/groomed.md`, copies the sprint plan's two lane queues over `docs/queue-feature.md` and `docs/queue-backlog.md`, and appends the sprint-14 row to `docs/sprints.tsv`.

Out of scope: any code, test, tool, or spec change, and any hand edit of what `groom` writes (none was needed: `make docs-lint` passes on its output).

Assumptions:

- The sprint plan was written after the sprint's last merge (#184), so its queues name no merged item as work and need no hand edit; no delivery planner plan exists for this change, so the package step's `plan-apply` leaves the copied queues as they are.

## Capabilities

### New Capabilities

None: the change commits planning records only and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `docs/backlog.md`, `docs/findings/` (five files folded and removed), `docs/metrics-feature.tsv`, `docs/metrics-backlog.tsv`, `docs/queue-feature.md`, `docs/queue-backlog.md`, `docs/sprints.tsv`.
- README.md: unchanged, no behavior or command changes.
- docs/architecture.md: unchanged, no layer, port, or roadmap item changes.
- CLAUDE.md: unchanged, no agent, workflow, command, or gate changes.
- docs/codebase-map.md: unchanged, no mapped file is added, moved, or removed (the findings files are records, not mapped).
