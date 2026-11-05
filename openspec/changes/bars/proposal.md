# Proposal

## Why

Every window draws its own status line with the path, a `[+]`, and the ruler, the mode shows only as `-- INSERT --` in the message row, and the tab line lists tab pages, so the open buffers are invisible until `:ls`. Language services, git, and diagnostics have nowhere to report, a plugin segment cannot say how much it matters when the terminal is narrow, and a narrow terminal simply cuts the line. The status and tab lines also allocate on every frame when a plugin has a segment or two tab pages exist. This change is outside the numbered roadmap of `docs/architecture.md` section 12: it is the bars change of the UI track the user approved (queue item 1), on the theme tokens of `theme-tokens` and the buffer list of item 7, and it reserves the place where item 10's language services and item 14's git status will report.

## What Changes

- One global status bar on the row above the message row, across the full width, as Neovim's `laststatus=3`: a mode pill (`NORMAL`, `INSERT`, `VISUAL`, `V-LINE`, `V-BLOCK`, `REPLACE`, `O-PENDING`, `COMMAND`) in a color per mode, then the current window's file with a modified dot, the git branch slot, and the diagnostics counts slot at the left; the plugins' segments, the reserved `lsp` slot, the file type, the encoding, the position as `row:col`, and the percent (`All`, `Top`, `Bot`, or `N%`) at the right. The branch, diagnostics, and `lsp` slots are empty until git and language services fill them; the `lsp` slot has its place, its priority, and a color per state (starting, ready, error).
- On a narrow terminal whole segments are dropped by priority, lowest first, until the rest fit; the mode and the file stay longest, and the file name is cut last.
- Windows stacked above others end in a flat horizontal separator row instead of a status line, and every separator, vertical or horizontal, is drawn in `WinSeparator`; segments are separated by spacing only, no powerline glyphs.
- Buffer tabs on the top row whenever two or more file buffers are listed or two or more tab pages exist: one tab per listed file buffer with its file icon, name, and modified dot, the current window's buffer selected, counts of the tabs that do not fit at either end, and from two tab pages the tab-page numbers at the right end. With one file buffer and one tab page there is no top row, as before.
- A host request `set_segment(text, priority)` lets a plugin place a status bar segment with a priority from 0 to 99; `set_status(text)` keeps working at priority 10. The API becomes 2.2.
- New theme groups for the mode pills, the diagnostics counts, and the `lsp` states, in every palette, with a new palette role for text on a strong accent; every new text group meets WCAG AA.
- The status and tab lines paint without allocating: no joined segment string and no per-tab label string per frame.
- The file icon table moves into the plugin API so the explorer and the buffer tabs share it, and a buffer remembers its icon name with its filetype.
- The planner's records: the `docs/backlog.md` entries from the plan notes.

Out of scope: filling the branch, diagnostics, and `lsp` slots (items 10 and 14), mouse clicks on tabs, buffer tab reordering and closing buttons, `:set laststatus` and `:set showtabline`, per-window status lines as an option, a winbar, the file name disambiguation of equal base names, and the message row's `-- INSERT --` (kept). CLAUDE.md's Status line no longer says "the windows half of 7", so the brief's fold-in needs no edit.

Assumptions: the top row shows from two listed file buffers (bufferline's default of hiding a lone tab), so a one-file session keeps its rows; scratch buffers such as the file tree get no tab, as Neovim leaves them unlisted; the encoding is always `utf-8`, the only one Carat reads and writes; the empty `lsp` slot takes no cells but keeps its place in the order, so filling it never moves the segments before it.

## Capabilities

### New Capabilities

- `status-bar`: the global status bar, its segments, their order, priorities, and colors, and the reserved slots.
- `buffer-tabs`: the top row of buffer tabs and tab-page numbers, its overflow counts, and when it shows.

### Modified Capabilities

- `screen-rendering`: the status line content and per-window status line requirements give way to the global bar; stacked windows are separated by a separator row; the tab line row follows the buffer tabs rule.
- `tab-pages`: the tab line shows tab-page numbers at the right end of the buffer tabs row.
- `plugin-host`: API 2.2 and the `set_segment` request.
- `color-themes`: the bar's groups are in every palette and meet AA.

## Impact

- Code: `carat/adapters/status_bar.rb` and `carat/adapters/tab_bar.rb` (new), `carat/adapters/frame_presenter.rb`, `carat/adapters/editor_assembly.rb`, `carat/domain/status_slots.rb` (new), `carat/domain/plugin_ui.rb`, `carat/domain/highlight.rb`, `carat/domain/themes.rb`, `carat/domain/frame.rb`, `carat/domain/display_width.rb`, `carat/domain/buffer.rb`, `carat/domain/buffer_list.rb`, `carat/use_cases/arrange_view.rb`, `carat/plugin_api.rb`, `carat/use_cases/plugins/plugin_link.rb`, `carat/use_cases/plugins/ui_requests.rb`, `carat/plugins/explorer/file_icons.rb`, `carat.rb`.
- Tests: `test/adapters_status_bar.rb` and `test/adapters_tab_bar.rb` (new), `test/adapters_frame_presenter.rb`, `test/adapters_screen_presenter.rb`, `test/domain_theme.rb`, `test/domain_plugin_manifest.rb`, `test/use_cases_plugins.rb`, `test/editor_plugins.rb`, `test/editor_screen.rb`, `test/editor_tabs.rb`, `test/adapters_assembly.rb`, and the editor tests whose rows move under the buffer tabs.
- Docs: `docs/compatibility.md`, `docs/architecture.md` sections 8.2 and 9, `docs/plugins.md`, `docs/codebase-map.md`, `README.md`, `docs/backlog.md`.
