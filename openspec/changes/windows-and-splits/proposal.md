# Proposal

## Why

Carat has exactly one window and one buffer: `:sp`, `:vs`, `Ctrl-W`, and `gt` all answer "Not implemented" or `E492`, and the next roadmap items, the explorer and the finder, need a side window to draw their lists in. Roadmap item 7 of `docs/architecture.md`, `buffers-windows-tabs`, gives the editor a window layout, tab pages, and a buffer list; this change delivers the windows and the tab pages, which is what the plugins need first.

## What Changes

This change delivers roadmap item 7, `buffers-windows-tabs`, minus the buffer list commands. The buffer list itself exists after this change, because every window shows one buffer from it and a closed window's modified buffer stays in it hidden, but `:ls`, `:bn`, `:bp`, `:bd`, `:b N`, and the second `E162` message of `:qa` stay for a later `buffer-list` change, which the architecture roadmap now names.

- Add a window layout per tab page: a tree whose leaves are windows, each with its own buffer, cursor, scroll position, and size, and whose inner nodes are horizontal or vertical splits. A window may be marked fixed-width, as Neovim's `winfixwidth`, so resizing and `Ctrl-W =` leave its width alone; this is what the explorer will use.
- Add tab pages, each holding one layout and its current window, and the editor state holds the buffer list, the tab pages, and the current tab page; the current window's buffer and cursor stay reachable as before so every existing use case keeps working.
- Add the window commands as `window.*` actions bound in `config/default.json`: `<C-w>s` and `<C-w>v` split showing the same buffer, `<C-w>h j k l` move to the neighbour, `<C-w>w` and `<C-w>W` cycle, `<C-w>p` goes to the previously used window, `<C-w>c` closes, `<C-w>o` closes every other window, `<C-w>=` equalizes, `<C-w>q` quits the window as `:q` does; a count before `<C-w>` is taken where Neovim takes one.
- Add the ex commands `:sp[lit] [file]`, `:vs[plit] [file]`, `:new`, `:vne[w]`, `:clo[se]`, and `:on[ly]`; change `:q`, `:wq`, and `:x` to close only the current window when more than one exists, closing the tab page when it was its last window and quitting the editor when it was the last window of the last tab page; change `:e file` to replace the buffer in the current window, reusing a buffer already in the list for that path; change `:wa`, `:qa`, `:wqa`, and `:xa` to act on every buffer in every tab page.
- Add tab pages as `tab.*` actions and ex commands: `:tabnew`, `:tabe[dit] [file]`, `:tabc[lose]`, `:tabo[nly]`, `:tabn[ext]`, `:tabp[revious]`, `:tabN[ext]`, `:tabfir[st]`, `:tabl[ast]`, and `gt` and `gT` with counts; the tab line is drawn on the top row only when more than one tab page exists, as Neovim's default `showtabline=1` does, each tab showing its number and its current window's file name with a modified marker, the current tab highlighted.
- Change the frame presenter to draw every window of the current tab page with its own gutter, text, and status line, a vertical separator between side-by-side windows in the status line highlight, the cursor in the current window, and the command line row at the bottom; a split that cannot give both windows one text row, or one text column plus the number column, fails with `E36: Not enough room`.
- Add table-driven editor tests for every binding and ex command, domain tests for the layout tree and the tab list, presenter tests for two-window frames in both orientations and a two-tab frame with the tab line, and extend the smoke test with `:vsplit`, `:tabnew`, and the quits; give every new command its row in `docs/compatibility.md` and every new action its row in `docs/actions.md`; update `CLAUDE.md`, the README, and `docs/architecture.md` (entity list, use case list, presenter description, roadmap note for item 7).

Out of scope, left for later changes: the buffer list commands `:ls`, `:bn`, `:bp`, `:bd`, `:b N` and the `E162` line, `winfixheight`, `winminwidth` and `winminheight` as options, `splitbelow` and `splitright`, `<C-w>t b x r R H J K L T`, resizing with `<C-w>+ - < >` and `:resize`, `<C-w>` followed by a count, `:Nsplit` and `:tabn N`, `tabm[ove]`, the `o_v` style `<C-w><C-w>` aliases, scroll binding, and `'hidden'` as an option. Keys and commands not listed keep reporting themselves as unknown.

Assumptions recorded here rather than asked:

- A split gives the new window the top or left half: `:split` makes the new window `h / 2` text rows high where `h` is the current window's text rows, the current window keeps the rest minus its status line, and `:vsplit` makes it `w / 2` columns wide with the current window keeping the rest minus the separator column, as Neovim does with `splitbelow` and `splitright` off. A count sets the new window's size, clamped so the current window keeps one text row or one text column plus its number column.
- The space of a closed window goes to the window after it in its split, or to the one before it when it was last, unless that window is fixed-width and the other is not, as Neovim's `win_altframe` chooses with `splitbelow` and `splitright` off.
- When the terminal is resized, the last window of each split absorbs the difference down to its minimum size, then the one before it, as Neovim does; fixed-width windows are skipped while another window can give or take the difference.
- `<C-w>h j k l` pick the neighbour that overlaps the cursor's screen row or column, counting columns by code point rather than display width.
- The buffer list keeps a buffer while some window shows it or it is modified; a buffer that is unmodified when its last window closes leaves the list and is read from disk again when edited later. `E141` names a buffer by its position in the list, starting at 1.
- `:e path` for a path already in the list shows that buffer without reading the file again, with the message in the form of the opened message built from the buffer in memory; `:e` and `:e!` on the current buffer's own path reload it in place so every window showing it sees the file's text.
- `:q!` on the last window of the last tab page while a modified hidden buffer exists shows that buffer in the window instead of quitting, as Neovim does, so no edit is lost; `:qa!` is the way out.
- Closing the last window showing a modified buffer with `:q`, `:close`, `:only`, `:tabclose`, or `:tabonly` keeps the buffer hidden in the list rather than refusing, as Neovim with `'hidden'` on does, and `:qa` then refuses with `E37`.
- `:wa` writes every modified buffer in list order, stopping at the first failure, and the message row shows the message of the last write.
- `{count}gt` goes to tab page `count` and does nothing when there is no such tab page; `{count}gT` goes `count` tab pages back, wrapping; `<C-w>w` and `<C-w>W` with a count go to window `count` in layout order, or the last window when the count is larger.
- `<C-w>o` and `:only` with one window, and `:tabonly` with one tab page, show Neovim's "Already only one window" and "Already only one tab page" messages; `:close` and `<C-w>c` on the last window of the last tab page report `E444: Cannot close last window`; `:tabclose` on the last tab page reports `E784: Cannot close last tab page`.
- The tab line label is a space, the tab number, a space, the current window's file name or `[No Name]`, ` [+]` when that buffer is modified, and a space; the row after the last label uses the tab line fill highlight. Inactive windows' status lines use their own highlight group.

## Capabilities

### New Capabilities

- `windows`: the window layout of a tab page: splitting, closing, moving between windows, cycling, the previous window, equalizing, fixed-width windows, the minimum size and `E36`, and how the buffer list behaves when windows close.
- `tab-pages`: creating, closing, and moving between tab pages with ex commands and `gt`/`gT`, and the tab line.

### Modified Capabilities

- `command-line-mode`: `:q`, `:wq`, and `:x` close the current window when others exist; `:e` reuses a listed buffer and reloads in place; `:wa`, `:qa`, `:wqa`, and `:xa` act on every buffer in every tab page.
- `screen-rendering`: the frame holds every window of the current tab page with a status line each, separators, the tab line, and the cursor in the current window.

## Impact

- New entities under `carat/domain/`: `layout.rb` (`LayoutNode`, `Layout`) and `tab_page.rb`; `window.rb` gains the buffer, the cursor, the rectangle, and the fixed-width flag; `editor_state.rb` holds the buffer list and the tab pages and derives the current window; `highlight.rb` gains the tab line and inactive status groups.
- New use cases under `carat/use_cases/windows/`: `split_window.rb`, `close_window.rb`, `focus_window.rb`, `resize_layout.rb`, `open_tab.rb`, `close_tab.rb`, `switch_tab.rb`; `files/quit.rb`, `files/open_file.rb`, `files/save_file.rb`, `files/execute_ex.rb`, and `dispatcher.rb` change; `editor_assembly.rb` wires them.
- `carat/adapters/frame_presenter.rb` lays out every window and the tab line; `screen_presenter.rb` maps the new highlight groups.
- `config/default.json` gains the `window.*` and `tab.*` bindings; the generated mirror follows.
- Tests: new `test/domain_layout.rb`, `test/editor_windows.rb`, `test/editor_tabs.rb`; `test/adapters_frame_presenter.rb`, `test/adapters_screen_presenter.rb`, `test/use_cases_ex.rb`, `test/editor_cmdline.rb`, `test/smoke_editor.rb`, and `test/domain_keymap.rb` extended, with their snapshots; `carat/doubles/editor_harness.rb` gains window helpers.
- Docs: `docs/compatibility.md`, `docs/actions.md`, `docs/architecture.md`, `CLAUDE.md`, `README.md`. No new dependencies and no new ports.
