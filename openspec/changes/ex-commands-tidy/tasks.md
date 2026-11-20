# Tasks

## 1. :normal

- [ ] 1.1 `carat/use_cases/ex/normal_command_handler.rb`: E192 sets a flag that stops every running `:normal`'s keys and lines, cleared by the outermost call (proved by "Too deep stops the lines left" and "A recursive normal over a range ends" in `test/editor_line_commands.rb`)
- [ ] 1.2 `docs/compatibility.md`: the `:normal` difference names the stop (proved by `make docs-lint`)

## 2. Substitute

- [ ] 2.1 `carat/use_cases/search/substitute_lines.rb`: `c` and `l` are refused before the string is kept (proved by "A refused flag keeps the last string" and "The list flag is refused" in `test/editor_substitute.rb`)
- [ ] 2.2 `carat/use_cases/search/substitute_lines.rb`: with `i` or `I` the last search is recompiled under the options (proved by "n after the i flag matches case by the options" and "N after the I flag ignores case by the options" in `test/editor_substitute.rb`)
- [ ] 2.3 `carat/domain/last_substitute.rb` and its readers: `case_mode` and `print` are symbols (proved by the flag rows of `test/domain_substitute.rb`)
- [ ] 2.4 `carat/domain/replacement.rb`: `group_at` and one block inserting a group, `recase` answering its text when nothing is recased (proved by the `group_at` rows and the expand rows of `test/domain_substitute.rb`, and `test/editor_substitute.rb`)
