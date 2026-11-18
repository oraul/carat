# Tasks

## 1. Domain and shared pieces

- [x] 1.1 Add the `addresses` member to `ExRange` and read it in `JoinCommandHandler` instead of the range text (`test/domain_ex_range.rb`, `test/editor_line_commands.rb`)
- [x] 1.2 Place the line commands' cursor through `EditorState#clamp_col` in `LineCommandHandler#place_cursor` (`test/editor_line_commands.rb`)
- [x] 1.3 Add `EditorState#normal_depth`, and let `Dispatcher` and `LeaveInsert` keep an open transaction while it is above 0 (`test/editor_line_commands.rb`, `test/editor_undo.rb`)
- [x] 1.4 Add `Outcome.printed` and join printed messages in `GlobalCommand#visit` (`test/editor_line_commands.rb`, `test/editor_global.rb`)

## 2. Ex commands

- [x] 2.1 Add `PrintCommandHandler` (`:p[rint]`) (`test/editor_line_commands.rb`, `test/use_cases_ex.rb`)
- [x] 2.2 Add `NormalCommandHandler` (`:norm[al]`), and build `HandleKey` before the ex commands are registered in `EditorAssembly`, registering both commands after `:>` and `:<` (`test/editor_line_commands.rb`, `test/use_cases_ex.rb`, `test/adapters_assembly.rb`)
- [x] 2.3 Keep the remap count of the key whose remap ran `:normal` across the keys it feeds in `HandleKey`, so a self-replaying binding stops at E223 (`test/editor_line_commands.rb`)

## 3. Docs

- [x] 3.1 Add the `:normal` and `:p` rows to `docs/compatibility.md`, fix its range sentence and the Global section, name the commands and the missing methods in map area 12, architecture section 5.2, and the README (`make docs-lint`, `test/lint.rb`)
