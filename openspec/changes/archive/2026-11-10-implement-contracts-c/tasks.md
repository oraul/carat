# Tasks

## 1. One E492

- [x] 1.1 `carat/domain/messages.rb`: `Messages.not_an_editor_command(name)`, called by `carat/use_cases/ex/execute_ex.rb` and `carat/use_cases/plugins/plugin_router.rb`. Tested by the E492 rows of the existing ex and plugin tests and by "no lint violations" in `test/lint.rb`.

## 2. Lint rules

- [x] 2.1 `test/lint.rb`: `message_literals`, `repeat_problems`, and `KNOWN_REPEATED_MESSAGES`, over `source_files`. Tested by "the repeated message rule" and "no lint violations".
- [x] 2.2 `test/lint.rb`: `shadow_problems`, over `carat/**/*.rb`. Tested by "the reader shadow rule" and "no lint violations".
- [x] 2.3 `test/lint.rb`: `binding_modes` and `binding_literal?`, over `source_files` outside `carat/plugins/`. Tested by "the hard-coded binding rule" and "no lint violations".
- [x] 2.4 `test/lint.rb.expected`: rewritten by `make snapshots`, the diff read.

## 3. Records

- [x] 3.1 `docs/codebase-map.md` (the lint line, `Messages`), `CLAUDE.md` (the binding convention names lint). Checked by `make gates` and `make docs-lint`.
- [x] 3.2 `docs/backlog.md`: remove the two closed lint entries, add the repeated messages entry for `messages-tidy`, record the periodic review at 186ddfb (notes 17 to 57) under the plan's owners, fold the duplicate palette entry, drop the stale wrap sentence, and name `periodic-blockers-a` on the 8d8832f blockers. `build/plan/queue.md` shortened under the docs-lint budget. Checked by `make docs-lint`.
