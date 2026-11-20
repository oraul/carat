# Tasks

## 1. The operators

- [x] 1.1 `carat/domain/operator_kind.rb` and `carat/use_cases/actions/operator_handler.rb` register `operator.swap_case`, `operator.lowercase`, `operator.uppercase`; `carat/adapters/editor_assembly.rb` passes `RecaseSelection` (proved by `test/editor_case_operators.rb` "the doubled forms" and "the visual modes", and `test/use_cases_actions.rb`)
- [x] 1.2 `carat/domain/operators.rb` `recase_range` and `recase_letter`, `carat/use_cases/operate.rb` `recase` (proved by `test/editor_case_operators.rb` "g~ gu gU over motions", "g~ gu gU over text objects", "g~ gu gU with counts", "multibyte letters", "the edges of the buffer")
- [x] 1.3 `config/default.caratrc` keymap lines in the five modes, mirrored by `make gen-config` (proved by `test/config_sync.rb` and the key rows)

## 2. Repeat and undo

- [x] 2.1 Rows for the dot command and one undo (proved by "dot repeats a case operator" and "one undo for a case operator" in `test/editor_case_operators.rb`)

## 3. Docs

- [x] 3.1 `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`, `README.md`, `CLAUDE.md` (proved by `test/use_cases_actions.rb`, `make docs-lint`, and `make lint`)

## 4. Review advisories fixed in place

- [x] 4.1 `carat/adapters/editor_assembly.rb` builds one `RecaseSelection` into a `recase_selection` reader and passes it to the operator and the selection handlers (proved by "the case operators and the visual case keys share the one RecaseSelection" in `test/adapters_assembly.rb`)
- [x] 4.2 `Domain::Operators.recase_row` slices and recases one row, used by `recase_range` and `RecaseSelection` (proved by the unchanged rows of `test/editor_case_operators.rb`)
- [x] 4.3 The label of the empty-line visual row in `test/editor_case_operators.rb` names the keys it sends
- [x] 4.4 `Operators.recase_rows` takes the rows and a column span per row and calls `buffer.set_lines` only when a rebuilt row differs from its original for the case keys (`:toggle`, `:lower`, `:upper`), always for `:replace`; `Operators.recase_range` and `RecaseSelection` both use it, so a visual case key over text already in the target case leaves no undo step while a visual `r{char}` over matching characters stays one undo step as before (proved by the three "a visual ... leaves no undo step" rows and the "a visual r over matching characters is still one undo step" row of `test/editor_case_operators.rb`; the operators spec line states the rule for the case keys and does not cover `r`)
- [x] 4.5 Closing advisories: `docs/codebase-map.md` lists `recase_row` and `recase_rows` in the `Operators` entry; the first comment of `carat/use_cases/actions/operator_handler.rb` is rewrapped; the per-letter rule's other callers are proved by the two normal `~` rows (ß, İ) under "multibyte letters" in `test/editor_case_operators.rb` and the "case escape on a dotted capital I" row of `test/editor_substitute.rb` (no specified behavior moves)
