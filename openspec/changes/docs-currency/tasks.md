# Tasks

## 1. CLAUDE.md

- [x] 1.1 `CLAUDE.md` Commands: every target named, each description left to `make help`, every rule kept; the `run_state.sh` bullet pointing to the script's header, with `restore` recreating a missing branch and `abandon` named. Checked by `make docs-lint` (budgets, dead paths) and `make gates` (docs).
- [x] 1.2 `CLAUDE.md` Git workflow and Pull requests: "unless explicitly asked" on both rules. Checked by reading the diff: no other rule line changes.
- [x] 1.3 `CLAUDE.md` at most 27,648 bytes. Checked by `wc -c` and `make docs-lint`.

## 2. docs/architecture.md

- [x] 2.1 Section 11: the directory tree kept, the per-file lists of the layers replaced by a pointer to `docs/codebase-map.md`. Checked by `make docs-lint` (dead paths).
- [x] 2.2 Sections 5.1 and 5.3: `SubstituteLines`, `DeleteLines`, `OpenSearchPrompt`, `PreviewSearch`, `RecallHistory`, and `ScrollWindow` named; checked by a scan that every plain use case class under `carat/use_cases/` (handlers, requests, records, and the plugin host aside) is named in the document.
- [x] 2.3 `docs/architecture.md` at most 87,064 bytes. Checked by `wc -c` and `make docs-lint`.

## 3. docs/backlog.md

- [x] 3.1 Remove the four entries this change fixes; add the seven entries of `build/plan/backlog.md`; queue the secret-pattern and binary-file entries in `content-gate-gaps` and the close-note entry in `backup-records`; restate the delivered-changes entry; name the backlog-items change in the review-area entry. Checked by `make docs-lint` (untagged queue items, content).

## 4. Gates

- [x] 4.1 `make gates` and `make docs-lint` pass.
