# Proposal

## Why

Sprint 10 closed with its five changes merged, its sprint-end review recorded, and its plan waiting in `build/plan/`: the backlog grooming, the two lane queues of sprint 11, and the findings files of its deliveries still unfolded. The plan is applied once, by its records change `sprint-10-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work before sprint 11 starts. It is outside the roadmap of `docs/architecture.md` section 12: delivery records, T0, outside the sprint count.

## What Changes

- `sh tools/run_state.sh history sprint-10-records` appends the pending history rows of both lanes: `markdown-reading-b` to `docs/metrics-feature.tsv` and `git-signs-trust` to `docs/metrics-backlog.tsv`.
- `sh tools/run_state.sh groom sprint-10-records` applies the sprint-10 plan: removes the five headings of `build/plan/groom.txt` from `docs/backlog.md`, folds the eight findings files under `docs/findings/` into it and removes them, appends `build/plan/groomed.md`, copies the sprint plan's two lane queues over `docs/queue-feature.md` and `docs/queue-backlog.md`, and appends the sprint-10 row to `docs/sprints.tsv`.
- `docs/queue-feature.md` is then taken from this delivery's plan, `build/plan/sprint-10-records/queue-feature.md`, which removes `git-signs-trust`, merged as #160 after the sprint plan was written, and draws `markdown-reading-c` into sprint 11.

Out of scope: any code, test, or tool change; removing the backlog heading "### git_signs rev-list can lazy-fetch from a promisor remote in an untrusted .git (security Medium, confidence 6)", which `git-signs-trust` listed and the next sprint's grooming removes as listed; the backlog lane's queue of this delivery's plan, which the package step's `plan-apply` copies.

Assumptions:

- The sprint plan's feature queue still names the merged `git-signs-trust` as item 1, and `plan-apply` copies only this change's lane (backlog, from its `chore/` branch), so the delivery planner's feature queue is copied by hand after `groom`, as its plan notes ask; both queue files stay under the queue budget (16519 bytes before the package step).

## Capabilities

### New Capabilities

None: the change commits planning records only and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `docs/backlog.md`, `docs/findings/` (eight files folded and removed), `docs/metrics-feature.tsv`, `docs/metrics-backlog.tsv`, `docs/queue-feature.md`, `docs/queue-backlog.md`, `docs/sprints.tsv`.
- README.md: unchanged, no behavior or command changes.
- docs/architecture.md: unchanged, no layer, port, or roadmap item changes.
- CLAUDE.md: unchanged, no agent, workflow, command, or gate changes.
- docs/codebase-map.md: unchanged, no mapped file is added, moved, or removed (the findings files are records, not mapped).
