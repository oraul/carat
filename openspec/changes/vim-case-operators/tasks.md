# Tasks

## 1. The operators

- [x] 1.1 `carat/domain/operator_kind.rb` and `carat/use_cases/actions/operator_handler.rb` register `operator.swap_case`, `operator.lowercase`, `operator.uppercase`; `carat/adapters/editor_assembly.rb` passes `RecaseSelection` (proved by `test/editor_case_operators.rb` "the doubled forms" and "the visual modes", and `test/use_cases_actions.rb`)
- [x] 1.2 `carat/domain/operators.rb` `recase_range` and `recase_letter`, `carat/use_cases/operate.rb` `recase` (proved by `test/editor_case_operators.rb` "g~ gu gU over motions", "g~ gu gU over text objects", "g~ gu gU with counts", "multibyte letters", "the edges of the buffer")
- [x] 1.3 `config/default.caratrc` keymap lines in the five modes, mirrored by `make gen-config` (proved by `test/config_sync.rb` and the key rows)

## 2. Repeat and undo

- [x] 2.1 Rows for the dot command and one undo (proved by "dot repeats a case operator" and "one undo for a case operator" in `test/editor_case_operators.rb`)

## 3. Docs

- [x] 3.1 `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`, `README.md`, `CLAUDE.md` (proved by `test/use_cases_actions.rb`, `make docs-lint`, and `make lint`)
