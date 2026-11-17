# Proposal

## Why

Sprint 12 closed with its changes merged (`checks-and-pr-lows`, `git-signs-status-b`, `windows-buffers-tidy`, `markdown-reading-c`, `planner-split-rule`, `lsp-container`), its sprint-end review recorded, and its plan waiting in `build/plan/`: the backlog grooming, the two lane queues of sprint 13, and the findings files of its deliveries still unfolded. The plan is applied once, by its records change `sprint-12-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work before sprint 13 starts. It is outside the roadmap of `docs/architecture.md` section 12: delivery records, T0, outside the sprint count.

## What Changes

- `sh tools/run_state.sh history sprint-12-records` appends the pending history rows of both lanes: `lsp-container` and `planner-split-rule`, each to its lane's `docs/metrics-*.tsv`.
- `sh tools/run_state.sh groom sprint-12-records` applies the sprint-12 plan: removes the 13 headings of `build/plan/groom.txt` (all listed by merged items) from `docs/backlog.md`, folds the seven findings files under `docs/findings/` into it and removes them, appends `build/plan/groomed.md`, copies the sprint plan's two lane queues over `docs/queue-feature.md` and `docs/queue-backlog.md`, and appends the sprint-12 row to `docs/sprints.tsv`.

Out of scope: any code, test, tool, or spec change, and any hand edit of what `groom` writes.

Assumptions:

- The sprint plan was written after the sprint's last merge (#171), so its queues name no merged item and need no hand edit; no delivery planner plan exists for this change, so the package step's `plan-apply` leaves the copied queues as they are.

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
