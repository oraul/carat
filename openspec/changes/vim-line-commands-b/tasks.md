# Tasks

## 1. Domain

- [ ] 1.1 Add `E477` and `REPORT` to `Domain::Messages` and use them in the move, copy, delete, substitute, and global command handlers and `SubstituteLines` (`test/editor_line_commands.rb`, `test/editor_global.rb`)
- [ ] 1.2 Read every address through `ExRange.line_of` in `resolve` and `target`, `target` answering the insertion row; add `ExRange#counted` (`test/domain_ex_range.rb`)
- [ ] 1.3 Add `RegisterCount.count` and let `ExGrammar` read `>` and `<` as names (`test/domain_ex_grammar.rb`, `test/domain_ex_range.rb`)

## 2. Line command handlers

- [ ] 2.1 Add `LineCommandHandler` and derive the delete, move, and copy handlers from it, the move compared in rows (`test/editor_line_commands.rb`, `test/editor_global.rb`, `test/use_cases_ex.rb`)
- [ ] 2.2 Add `JoinCommandHandler` (`:j[oin]`) and `ShiftCommandHandler` (`:>`, `:<`), registered after `:t` in `EditorAssembly` (`test/editor_line_commands.rb`, `test/use_cases_ex.rb`)

## 3. Docs

- [ ] 3.1 Add the `:j`, `:>`, `:<` rows to `docs/compatibility.md` and the ranged commands to its differences, name the commands in map area 12, architecture section 5.2, and the README (`make docs-lint`, `test/lint.rb`)
