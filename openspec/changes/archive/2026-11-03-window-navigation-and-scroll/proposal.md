# Proposal

## Why

A user reports that after a split they cannot move to the other window, that they cannot move focus into or out of the file tree, and that `<PageUp>` and `<PageDown>` do nothing. Reproduced in a pseudo-terminal at e375e4c: `<C-w>l` typed in one burst moves to the right window, but `<C-w>` followed by `l` more than `timeoutlen` (500 ms) later does not, because the editor drops a lone prefix when the wait runs out, and the `l` then runs on its own (a cursor move in a file window, "open" in the tree). Neovim never times out on its built-in multi-key commands such as `<C-w>l`, `gg`, or `zz`; it waits for the second key. No scroll command exists at all. This is a user-reported bug fix taken before `search-and-substitute` (roadmap item 6), outside the roadmap order; the scroll commands finish the window half of roadmap item 7.

## What Changes

- In normal, operator-pending, and the visual modes, keys that only begin a binding (bound to nothing themselves) wait for the next key with no time limit, as Neovim's built-in commands do; Escape or any key that continues no binding drops them. A sequence that is bound and also begins a longer binding still resolves after `timeoutlen`, and insert and command-line modes keep resolving a pending prefix after `timeoutlen` (the keys are inserted as text), as Neovim's mappings do.
- `<C-w>h j k l w W p` therefore move focus between split windows and between the file tree and the file windows, both ways, however slowly the second key is typed. No new binding is needed for the tree: its keymap does not bind `<C-w>`, so the window commands fall through to the normal keymap, which the tests already prove for keys typed together.
- New scroll actions with Neovim's semantics, bound in normal mode and the three visual modes, and `<PageUp>`/`<PageDown>` also in insert mode: `scroll.page_down` and `scroll.page_up` (`<C-f>`, `<PageDown>`, `<C-b>`, `<PageUp>`, by count pages of the window height minus two), `scroll.half_page_down` and `scroll.half_page_up` (`<C-d>`, `<C-u>`, by the `scroll` option, half the window when 0, a count setting the option first, cursor moving by the same number of lines), `scroll.line_down` and `scroll.line_up` (`<C-e>`, `<C-y>`, by count lines with the cursor kept in view), and `scroll.cursor_top`, `scroll.cursor_middle`, `scroll.cursor_bottom` (`zt`, `zz`, `zb`, with a count going to that line first).
- A new option `scroll` (number, default 0) in `config/default.caratrc` and `Options`; `:set scroll` answers "Not implemented" like the other options until `:set` arrives.
- The unbound-key examples in the specs and tests move from `z`, which now begins `zz`, `zt`, and `zb`, to `Q`.
- Documentation: `docs/actions.md`, `docs/compatibility.md` (a Scrolling section, the prefix wait under Command grammar), the code map, and the README key list.

Out of scope: scrolling past the end of the buffer (the view never shows rows after the last line beyond what a full window needs, as today), `z<CR>`, `z.`, `z-`, horizontal scrolling (`zh`, `zl`, `zs`, `ze`), `<S-Up>`/`<S-Down>`, smooth scrolling, a window-local `scroll`, `:set scroll=`, and `<C-w>` commands in modes other than normal.

## Capabilities

### New Capabilities

- `scrolling`: page, half-page, and line scrolling of the current window and the `z` commands that place the cursor line at the top, middle, or bottom, with the cursor kept in view and the `scroll` option.

### Modified Capabilities

- `keymap-config`: a lone prefix waits for the next key without a time limit in the grammar modes, and the unbound-key example moves to `Q`.
- `windows`: moving between windows works with any delay between `<C-w>` and its second key, and between the file tree and the file windows.
- `config-files`: `scroll` is a number option.

## Impact

- Code: `carat/use_cases/handle_key.rb` (a `:waiting` result for a lone prefix in a grammar mode), `carat/adapters/input_controller.rb` (no deadline while waiting), new `carat/use_cases/windows/scroll_window.rb` and `scroll_request.rb`, new `carat/use_cases/actions/scroll_handler.rb`, `carat/adapters/editor_assembly.rb`, `carat.rb`, `carat/domain/options.rb`, `carat/use_cases/ex/set_command_handler.rb`; `config/default.caratrc` and the generated `carat/domain/default_config.rb`.
- Tests: `test/editor_normal.rb` (the prefix wait), `test/editor_windows.rb` and `test/editor_explorer.rb` (focus moves with a wait between the keys), a new `test/editor_scroll.rb` table, `test/smoke_editor.rb` (`<C-w>l` with a pause and `<PageDown>` in a pseudo-terminal), `test/domain_keymap.rb`, `test/editor_grammar.rb`, `test/domain_options_config.rb`.
- No new dependency. Allocations per key stay at the baseline: the scroll commands allocate nothing per key beyond the command, and the prefix change adds no allocation.

Assumptions recorded here:

- Waiting without a limit applies to every lone prefix in the grammar modes, user bindings included, since the keymap does not tell built-in commands from mappings and dropping the keys after a delay is what the user reported as broken.
- `<C-f>` at the end of the buffer moves the cursor to the last line (where Neovim's repeated `<C-f>` ends), and `<C-b>` at the start leaves the cursor where it is (Neovim beeps).
- `scroll` is global, as every option is until local options arrive with roadmap item 9.
