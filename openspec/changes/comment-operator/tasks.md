# Tasks

## 1. The toggle

- [ ] 1.1 `carat/domain/comments.rb`: the marker table, `commented?`, `toggle`, and `block` (proved by `test/editor_comments.rb` "Uncomment removes the marker and one space", "A mixed range is commented", "Blank lines are untouched", "The marker goes at the smallest indent", "A line of only the marker becomes empty", "An unknown filetype uses the default marker")
- [ ] 1.2 `carat/domain/operator_kind.rb` `COMMENT`, `carat/use_cases/operate.rb` comment branch, `carat/use_cases/actions/operator_handler.rb` registration (proved by `test/editor_comments.rb` "gcc comments the line", "gc with a motion and a count", "gc with a text object", "gcc never deletes text", "One undo restores the toggled lines", "Dot repeats the toggle")
- [ ] 1.3 `carat/domain/command_grammar.rb` doubled last key for `gc` (proved by `test/editor_comments.rb` "gcc with a count" and `test/domain_grammar.rb` row "the last key of gc doubles it")

## 2. Visual and the text object

- [ ] 2.1 `carat/use_cases/visual/comment_selection.rb` wired in `carat/adapters/editor_assembly.rb` (proved by `test/editor_comments.rb` "Visual gc", "Visual line gc uncomments", "Visual block gc toggles whole lines")
- [ ] 2.2 `carat/domain/text_objects.rb` `textobject.comment` (proved by `test/editor_comments.rb` "dgc deletes the comment block", "ygc yanks the comment block", "dgc off a comment does nothing")

## 3. Configuration and docs

- [ ] 3.1 `config/default.caratrc` keymap lines, `make gen-config` mirror (proved by `test/config_sync.rb` and `test/editor_comments.rb`)
- [ ] 3.2 `docs/actions.md`, `docs/compatibility.md`, `docs/codebase-map.md`, `docs/architecture.md`, README.md (proved by `test/use_cases_actions.rb` "the action table and docs/actions.md list the same actions" and `make lint`)
