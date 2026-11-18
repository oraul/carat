# Proposal

## Why

Sprint 16 closed with its six changes merged (`secret-patterns`, `git-signs-transport`, `vim-line-commands-b`, `plugin-lazy-activate`, `sprint-size-six`, `merge-main-path`), its sprint-end review recorded, and its plan waiting in `build/plan/` (`build/plan/sprint` names `sprint-16`, `docs/sprints.tsv` ends at `sprint-15`): the backlog grooming, the two lane queues of sprint 17, and the findings files of its deliveries still unfolded. The plan's security-first item, `moved-review-carry`, merged as #199, so its blocking finding is resolved and the plan applies. It is applied once, by its records change `sprint-16-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work before sprint 17 starts. It is outside the roadmap of `docs/architecture.md` section 12: delivery records, T0, outside the sprint count.

## What Changes

- `sh tools/run_state.sh history sprint-16-records` appends the pending history rows of both lanes to `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`.
- `sh tools/run_state.sh groom sprint-16-records` applies the sprint-16 plan: removes the 8 headings of `build/plan/groom.txt` (1 listed by `secret-patterns`, 4 by `git-signs-transport`, 3 by `vim-line-commands-b`) from `docs/backlog.md`, folds the findings files under `docs/findings/` into it and removes them (those of `git-signs-transport`, `merge-main-path`, `moved-review-carry`, `plugin-lazy-activate`, `secret-patterns`, `sprint-15-records`, `sprint-size-six`, and `vim-line-commands-b`), appends `build/plan/groomed.md`, copies the sprint plan's two lane queues over `docs/queue-feature.md` and `docs/queue-backlog.md`, and appends the sprint-16 row to `docs/sprints.tsv`.
- The branch first takes in main at #199 (`merge-main`), so `moved-review-carry`'s findings file is folded and its history row is not appended twice.

Out of scope: any code, test, tool, or spec change, and any hand edit of what `groom` writes beyond a line `make docs-lint` refuses.

Assumptions:

- The security-first section of the backlog queue applies with `moved-review-carry` already delivered; the package step's `plan-apply` of `build/plan/sprint-16-records/queue-backlog.md` drops that delivered section and adds the Pool 1 item `moved-review-carry-b`, and appends the planner's four pipeline entries to `docs/findings/sprint-16-records.md`.
- The feature queue stays as `groom` copies it from `build/plan/queue-feature.md`.

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
