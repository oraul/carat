# Proposal

## Why

Sprint 17 closed with its six changes merged (`tab-close-d`, `pipeline-diet`, `vim-folds-b`, `pipeline-diet-b`, `squash-body-full`, `vim-line-commands-c`), its sprint-end review recorded, and its plan waiting in `build/plan/` (`build/plan/sprint` names `sprint-17`, `docs/sprints.tsv` ends at `sprint-16`): the backlog grooming, the two lane queues of sprint 18, and the findings files of its deliveries still unfolded. It is applied once, by its records change `sprint-17-records`, so the queues, the backlog, the metrics history, and the sprints file match the merged work before sprint 18 starts. It is outside the roadmap of `docs/architecture.md` section 12: delivery records, T0, outside the sprint count.

## What Changes

- `sh tools/run_state.sh history sprint-17-records` appends the pending history rows of `squash-body-full` to `docs/metrics-backlog.tsv` and of `vim-line-commands-c` to `docs/metrics-feature.tsv` (committed first, with the late findings of `vim-line-commands-c`); a second run finds nothing pending.
- `sh tools/run_state.sh groom sprint-17-records` applies the sprint-17 plan: removes the 14 headings of `build/plan/groom.txt` (3 listed by `tab-close-d` and `vim-line-commands-c`, 5 fixed by merged commits, 6 duplicates), 5 of them from `docs/backlog.md` and 9 (3 fixed, 6 duplicate copies) from the findings files it folds, folds the 7 findings files under `docs/findings/` into `docs/backlog.md` and removes them (those of `pipeline-diet`, `pipeline-diet-b`, `sprint-16-records`, `squash-body-full`, `tab-close-d`, `vim-folds-b`, and `vim-line-commands-c`), appends `build/plan/groomed.md`, copies the sprint plan's two lane queues over `docs/queue-feature.md` and `docs/queue-backlog.md`, and appends the sprint-17 row to `docs/sprints.tsv`.
- Three backticked paths to removed findings files that `make docs-lint` refuses, two in `docs/backlog.md` and one in `docs/queue-backlog.md`, are put in prose.
- The review's advisories in the files this change edits are fixed in place: `docs/queue-feature.md` names the backlog heading of the fold mark leak instead of a line of the removed `vim-folds-b` findings file, and `docs/queue-backlog.md` places `round-limit-resume` first of the pool's T1 defects, as its Pool orders it, both kept within the queues' byte budget; the two backlog duplications wait for the next grooming, recorded in this change's findings.

Out of scope: any code, test, tool, or spec change, and any hand edit of what `groom` writes beyond a line `make docs-lint` refuses and the review advisories named above.

Assumptions:

- The queues are the planner's revision in place after the first run's stop: the user's Sprint 18 choice (features `guide-colors`, `facet-palette`, `background-default`; backlog `groom-proof`, `sign-colors`, `lsp-tidy`).
- `groom.txt` no longer holds the refused duplicate line for "A records change that resumes into the planner loses the planner's files (sprint-16-records retro)", so both copies from the `vim-folds-b` findings file are folded into `docs/backlog.md` until `groom-proof` narrows the guard; no finding is reworded.

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
