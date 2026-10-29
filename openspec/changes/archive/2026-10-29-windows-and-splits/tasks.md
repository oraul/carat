# Tasks

## 1. Layout, tab pages, and the state

- [x] 1.1 Extend `carat/domain/window.rb` with the buffer, the cursor, the rectangle, the fixed-width flag, `show`, `copy_from`, and `gutter_width`; add `carat/domain/layout.rb` (`LayoutNode`, `Layout` with `split`, `close`, `neighbour`, `equalize`, `arrange`, `leaves`, `window_at`) and `carat/domain/tab_page.rb`; add them to `carat.rb`; verify with `test/domain_layout.rb` covering split sizes with and without a count, E36, close and the space it returns, neighbour lookup in both orientations, equalize with a fixed-width window, arrange after a resize, and window numbering
- [x] 1.2 Change `carat/domain/editor_state.rb` to hold `buffers`, `tabs`, and `tab_index`, derive `tab`, `window`, `buffer`, and `cursor`, and own `load`, `release`, `buffer_for`, `modified_buffer`, `shown?`, `add_tab`, `close_tab`, and `switch_tab`; add the tab line and inactive status highlight ids to `carat/domain/highlight.rb`; verify with `test/domain_layout.rb` rows for the buffer list and tab navigation with counts and that every existing test program still passes under `make test`

## 2. Window and tab use cases

- [x] 2.1 Add `carat/use_cases/windows/split_window.rb`, `close_window.rb`, `focus_window.rb`, and `resize_layout.rb`; change `carat/use_cases/files/quit.rb` to close a window or quit the editor with the hidden-buffer rules and add `Quit#all`; change `carat/use_cases/files/open_file.rb` to reuse a listed buffer and reload in place and `carat/use_cases/files/save_file.rb` to write a given buffer; verify with `test/use_cases_ex.rb` rows for `:q` with two windows, `:e` reuse, and `:wa` over several buffers
- [x] 2.2 Add `carat/use_cases/windows/open_tab.rb`, `close_tab.rb`, and `switch_tab.rb`; extend `carat/use_cases/files/execute_ex.rb` with `:sp`, `:vs`, `:new`, `:vne[w]`, `:clo[se]`, `:on[ly]`, `:tabnew`, `:tabe[dit]`, `:tabc[lose]`, `:tabo[nly]`, `:tabn[ext]`, `:tabp[revious]`, `:tabN[ext]`, `:tabfir[st]`, `:tabl[ast]`, and the buffer-list forms of `:wa`, `:qa`, `:wqa`, `:xa`; verify with `test/use_cases_ex.rb` rows for every new command and `E784`, `E444`, and the "Already only one" messages
- [x] 2.3 Route `window.*` and `tab.*` actions with their counts in `carat/use_cases/dispatcher.rb`, wire every new use case in `carat/adapters/editor_assembly.rb`, bind `<C-w>s v h j k l w W p c o = q` and `gt gT` in `config/default.json`, and run `make gen-config`; verify with `test/config_sync.rb` and `test/domain_keymap.rb`

## 3. Rendering

- [x] 3.1 Change `carat/adapters/frame_presenter.rb` to arrange and paint every window of the current tab page with its gutter, text, status line, separators, the tab line, and the cursor in the current window, and `carat/adapters/screen_presenter.rb` to map the new highlight groups; verify with `test/adapters_frame_presenter.rb` scenarios for two stacked windows, two windows side by side, the status line highlights, the cursor in the bottom window, and a two-tab frame, and `test/adapters_screen_presenter.rb` for the new colors

## 4. Whole-editor tests, smoke test, and documentation

- [x] 4.1 Extend `carat/doubles/editor_harness.rb` with `window_count`, `tab_count`, `tab_index`, `window_index`, and `windows`; add `test/editor_windows.rb` with a table row per scenario of the windows spec and `test/editor_tabs.rb` with one per scenario of the tab-pages spec; extend `test/editor_cmdline.rb` with the multi-window `:q`, `:wq`, `:x`, `:e`, `:wa`, `:qa`, and `:wqa` scenarios; verify every row passes under `make test`
- [x] 4.2 Extend `test/smoke_editor.rb` with a session that runs `:vsplit`, `:tabnew`, `:q`, `:q`, and `:q` in the pseudo-terminal and asserts the separator, the tab line, and the clean exit; verify it passes under `make test`
- [x] 4.3 Add one row per command to `docs/compatibility.md` in new "Windows" and "Tab pages" sections with their tests, update the ex and normal-mode notes, add every `window.*` and `tab.*` action to `docs/actions.md`, update the Status and Layout entries of `CLAUDE.md`, the README, and `docs/architecture.md` (section 4 entities, section 5.3 use cases, section 8.2 presenter, the roadmap note for item 7 naming the later `buffer-list` change); verify every new command has a row and every new action a line
- [x] 4.4 Run `make snapshots`, review the diff, then `make check` (build, gen-config, test, diagnose) and diff `make types` against `main` for new `untyped` members on the window entities; verify everything passes and `spinel-doctor` reports clean

## Workflow follow-up

- Run the security review on the committed branch, then archive the change, open the pull request, and squash-merge it after CI is green.
