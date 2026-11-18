# Proposal

## Why

Sprint 18 closed with its six changes merged (`guide-colors`, `groom-proof`, `facet-palette`, `backlog-throughput`, `background-default`, `sign-colors`), its sprint-end review recorded, and its plan waiting in `build/plan/` (`build/plan/sprint` named `sprint-18`, `docs/sprints.tsv` ended at `sprint-17`): the backlog grooming, the two lane queues of sprint 19, and the findings files of its deliveries still unfolded. It is applied once, by its records change `sprint-18-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work before sprint 19 starts. It is outside the roadmap of `docs/architecture.md` section 12: delivery records, T0, outside the sprint count.

## What Changes

- `sh tools/run_state.sh history sprint-18-records` appends the pending history rows of `background-default` to `docs/metrics-feature.tsv` and of `groom-security-mark` (#214, the security fix that stopped the first start) to `docs/metrics-backlog.tsv`; a second run finds nothing pending.
- `sh tools/run_state.sh groom sprint-18-records` applies the sprint-18 plan: removes the 4 headings of `build/plan/groom.txt` (2 listed by `groom-proof`, 1 fixed by 53b1e58, 1 merged into a near-same entry), folds the 7 findings files under `docs/findings/` into `docs/backlog.md` and removes them (those of `background-default`, `backlog-throughput`, `facet-palette`, `groom-proof`, `guide-colors`, `sign-colors`, and `sprint-17-records`), appends `build/plan/groomed.md`, copies the sprint plan's two lane queues over `docs/queue-feature.md` and `docs/queue-backlog.md`, and appends the sprint-18 row to `docs/sprints.tsv`.

Out of scope: any code, test, tool, or spec change, and any hand edit of what `groom` writes beyond those design.md records: one docs-lint fix in the backlog and the review's in-place fixes of the two queues.

Assumptions:

- The queues are the planner's revision at the user's request, applied as they stand: the Sprint 19 features `gutter-signcolumn`, `match-paren`, and `cursor-and-messages`, and the backlog items `review-lite`, `quality-first-pass`, and `contributor-checklist` under the user-approved exception.
- `docs/queue-backlog.md` drops its "Security first" section, and both queues their Decisions bullet, naming `groom-security-mark`, merged as #214 after the plan was written (a review finding fixed in place).
- The sprint-18 quality notes are already in `build/plan/groomed.md` or groomed as fixed; the review findings not fixed in place go to this change's findings file at packaging.

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
