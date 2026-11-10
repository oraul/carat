# Tasks

## 1. Queue

- [x] 1.1 `docs/queue.md`: the planner's queue, `spinel-bump`, `gd-ghost-tab`, `finder-grep`, `finder-pickers`, `markdown-preview`, `periodic-blockers-b`, `csv-viewer`, `backlog-compaction` first, each with a tier, a size, the problem, and the acceptance; the hold and its resume in the header; the standing decisions in Decisions. Checked by `make docs-lint` (budget, queue tags).

## 2. Backlog

- [x] 2.1 `docs/backlog.md`: the periodic findings at ce6abdb folded into the entries naming their locations, the rest added as new entries, the stale UI group entry replaced. Checked by `make docs-lint` (paths, content) and a scan that no two headings are adjacent.
- [x] 2.2 `docs/backlog.md`: the session-link footer entry confirmed as standing, the `image-viewer` entry under discussion and parked with the GNOME Terminal decoder. Checked by `make docs-lint`.

## 3. README

- [x] 3.1 `README.md`: the goals' current order and the resume after a hold, `/status` then `/deliver` for the first item. Checked by `make docs-lint` and `make gates` (docs).

## 4. Gates

- [x] 4.1 `openspec validate queue-handoff --strict`, `make spec-validate`, `make gates`, and `make docs-lint` pass.
