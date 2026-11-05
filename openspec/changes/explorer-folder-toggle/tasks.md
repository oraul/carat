# Tasks

## 1. Planner records

- [x] 1.1 `docs/queue.md` from `build/plan/queue.md`, the four entries of `build/plan/backlog.md` in `docs/backlog.md`, and the wrap-width entry of `docs/backlog.md` corrected to four comments (`carat/ports/terminal_port.rb` line 4, `carat/use_cases/dispatcher.rb` line 37); verified by `make docs-lint`.

## 2. The tree keys

- [ ] 2.1 `carat/plugins/explorer/plugin.rb`: bind `<CR>` to `plugin.explorer.toggle_dir` in `keymap`, and reorder the `HELP` line to `<CR>/o toggle  l open  h close`; rows in `test/editor_explorer.rb` for `<CR>`, `l`, `h`, and `o` on a collapsed and an expanded directory, a file, a nested directory, and the tree reached through Ctrl-W, each with the cursor row, and the `?` row, pass through `make test-one T=test/editor_explorer.rb`.
- [ ] 2.2 `carat/plugins/explorer/tree.rb`: remove the uncalled `show_hidden?`; `make test-one T=test/plugins_explorer.rb` and `make lint` pass.

## 3. Documentation and checks

- [ ] 3.1 `docs/actions.md`: `<CR>` moves from the `plugin.explorer.open` row to the `plugin.explorer.toggle_dir` row, and the action descriptions match the manifest; the actions test in `make test-one T=test/lint.rb` and `make docs-lint` pass.
- [ ] 3.2 `make gates` and `make spec-validate` pass.
