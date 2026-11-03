# Tasks

## 1. A lone prefix waits for its next key

- [x] 1.1 Add a pseudo-terminal check to `test/smoke_editor.rb` that splits, presses `<C-w>`, pauses past timeoutlen, presses `l`, and finds the cursor in the right window; verify it fails on the current code (the reproduction) before the fix
- [x] 1.2 Return `:waiting` from `HandleKey#step` for a pure prefix in a grammar mode (`carat/use_cases/handle_key.rb`) and keep no deadline for it in `InputController` (`carat/adapters/input_controller.rb`); verify with `test/editor_normal.rb` rows for the wait outlasting timeoutlen, Escape dropping the prefix, and insert mode still resolving after timeoutlen, and `make test-one T=test/smoke_editor.rb`
- [x] 1.3 Add rows with a wait between `<C-w>` and its key to `test/editor_windows.rb` (l, w) and `test/editor_explorer.rb` (out of the tree and back, `<C-w>w` cycling, `<C-w>p`); verify with `make test-one` on both
- [x] 1.4 Move the unbound-key examples from `z` to `Q` in `test/domain_keymap.rb`, `test/editor_grammar.rb`, and `test/editor_normal.rb`; verify with `make test-one` on each
- [x] 1.5 Document the wait in `docs/compatibility.md` (Command grammar) and `docs/architecture.md` section 8.1 where it describes the timeoutlen wait; verify with `make docs-lint`

## 2. The scroll option

- [x] 2.1 Add the `scroll` member, its `KINDS` entry, and its `apply` branch to `carat/domain/options.rb`, `option.scroll 0` to `config/default.caratrc`, `scroll` and `scr` to the pending names of `carat/use_cases/ex/set_command_handler.rb`, and run `make gen-config`; verify with `test/domain_options_config.rb` rows and `make config-current`

## 3. Scroll commands

- [x] 3.1 Scaffold `ScrollWindow` with `make new-use-case NAME=scroll_window DIR=windows AREA=11` and add `ScrollRequest` beside `FocusRequest`; implement the page, half-page, line, and z variants with the clamp and the cursor kept in view; verify with `make lint`
- [x] 3.2 Scaffold `ScrollHandler` with `make new-action NAME=scroll ACTION=scroll.page_down AREA=11`, register the nine `scroll.*` names with their variants and the shared `ScrollWindow` built once in `EditorAssembly`; verify with `test/use_cases_actions.rb` (table and docs agree) and `test/adapters_assembly.rb`
- [x] 3.3 Bind the keys in `keymap.normal`, the three visual maps, and `<PageUp>`/`<PageDown>` in `keymap.insert` in `config/default.caratrc`, then `make gen-config`; verify with `make config-current`
- [x] 3.4 Add `test/editor_scroll.rb` (`make new-test NAME=editor_scroll AREA=11`) with a table row per scrolling-spec scenario, visual and insert mode rows, and the before-first-render case; verify with `make test-one T=test/editor_scroll.rb`
- [x] 3.5 Add `<PageDown>` to the pseudo-terminal check in `test/smoke_editor.rb`; verify with `make test-one T=test/smoke_editor.rb`
- [x] 3.6 List the nine actions in `docs/actions.md`, add a Scrolling section to `docs/compatibility.md` with its differences from Neovim, the `scroll` option under Options read so far, the README key list, and the code map entries; verify with `make docs-lint` and `make gates`

## 4. Integration

- [x] 4.1 Run `make test`, `make diagnose`, and `make bench-budget`, and compare the allocations per key with `make metrics` against the baseline; all pass with allocations unchanged

## Workflow follow-up

- Archive the change with `openspec archive window-navigation-and-scroll -y` in the package step.
