# Tasks

## 1. Edge-case tests first

- [x] 1.1 `test/editor_windows.rb`: a split, Ctrl-W c, and Ctrl-W o from the last line, and a split, `:close`, and `:new` with Ctrl-W o over an empty buffer (proved by the tests' labels)
- [x] 1.2 `test/editor_tabs.rb`: `:tabclose`, `:tabonly`, and `:tabn` back to a tab page left on its last line, and `:tabnew` with `:tabclose` and `:tabclose 1` over an empty buffer (proved by the tests' labels)

## 2. Part a's late findings

- [x] 2.1 Finding 25: `WiringLedger#record` drops the replace branch and `test/adapters_assembly.rb` the probe row (proved by "the ledger answers no object for a pair it never recorded")
- [x] 2.2 Findings 22 to 24: `holder_problems` calls `readerless_keyword_problems` or `rbs_keyword_problems`; `ledger_records` and `passes?` replace `ledger_slots` and the two passed-object checks; `wiring` is `assembly_text` (proved by the holder rule's self-tests)
- [x] 2.3 Finding 27: `reader_problems` refuses a public `attr_accessor` (proved by the self-test "the readerless directory rule")
- [x] 2.4 Finding 26: `session` and the empty-buffer case call one `session_on` builder that takes the file's text in `test/editor_key_hints.rb` and `test/editor_palette.rb`, and `empty_session` goes (proved by the tests' labels)
- [x] 2.5 Finding 28: `docs/architecture.md` section 8's composition root sentence (proved by `make docs-lint`)

## 3. The windows area without readers

- [x] 3.1 `carat/use_cases/windows/`: the 11 use cases replace their 20 readers with `# @rbs @name: Type` lines (proved by `test/editor_windows.rb`, `test/editor_tabs.rb`, `test/editor_floats.rb`, `test/editor_slots.rb`, and `make lint`)
- [x] 3.2 `carat/adapters/editor_assembly.rb` records the 20 objects after each construction, `test/adapters_assembly.rb` reads them with `w.held`, and `READERLESS_DIRS` gains `carat/use_cases/windows/` (proved by `test/adapters_assembly.rb` and `make lint`)

## 4. Docs and measurements

- [x] 4.1 `docs/examples.md` and `docs/codebase-map.md` describe the readerless golden use case and the rule (proved by `make docs-lint` and `make lint`)
- [ ] 4.2 Measure analysis time and rounds of both compile roots, the binary's size, and time per key on main and on the branch for the pull request (`make metrics`)
