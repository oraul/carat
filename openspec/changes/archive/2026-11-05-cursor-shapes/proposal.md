## Why

The theme names a `CursorLine` group and every palette colors it, but nothing paints it, so the cursor's line is as hard to find as in a plain terminal. The cursor is a bar in insert mode and a block otherwise, with no shape for replace mode, and leaving the editor sets a block cursor instead of the terminal's own, so a user whose shell uses a bar or an underline gets a block back; the screen is entered before the `ensure` that leaves it, so a failure while opening the file skips the restore. This change is outside the numbered roadmap of `docs/architecture.md` section 12: it is the second change of the UI track the user approved, split from `theme-tokens` (queue item 2), extending the rendering of item 8.

## What Changes

- With the `cursorline` option on, the cursor's line in the current window is drawn over the `CursorLine` background: its text keeps its syntax colors, a group with a background of its own (the selection, search matches) keeps that background, the rest of the window row up to its right edge is filled, and the line number is drawn in `CursorLineNr`. Other windows show no cursor line. At 16 colors the line is underlined, as the theme says.
- `option.cursorline true|false` in the configuration, and `:set cursorline` (`cul`) with Vim's boolean forms (`nocul`, `invcul`, `cul!`, `cul?`). Neovim's default is off; the shipped configuration turns it on.
- The cursor shape follows the mode: a block in normal, visual, operator-pending, and command-line mode, a bar in insert mode, and an underline in replace mode.
- Leaving the screen resets the cursor shape to the terminal's own (`DECSCUSR` 0) instead of a block, and the entry point enters the screen and opens the file inside the `ensure` that leaves it, so a quit by `:q`, `:wq`, closing the last window, `SIGTERM`, `SIGINT`, or an error restores the cursor.
- The planner's records: `docs/backlog.md` entries from the plan notes (the wrap-width comments, the delivered-changes list, the spec preview links, the positional `Tree` flag, the map's Designs lines).

Out of scope: `cursorlineopt`, a cursor line per window (`setlocal`), `guicursor` and a configurable shape table, replace mode itself (`R`, which arrives with its own change; the shape is ready for it), blinking, and a `CursorLineSign` group.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `screen-rendering`: the cursor shape requirement gains replace mode's underline and the other modes; leaving the screen restores the terminal's own cursor; a new requirement draws the current line of the current window.
- `editor-startup`: every exit path, an error while opening the file included, restores the terminal's cursor and screen.
- `color-themes`: every group on the cursor line keeps 3:1 contrast, as on the selection, and is underlined at 16 colors.

## Impact

- Code: `carat/domain/highlight.rb` (the cursor-line layer of ids), `carat/domain/themes.rb` (the layer's colors), `carat/domain/options.rb` (`cursorline`), `carat/domain/frame.rb` (lifting a span of cells onto the layer), `carat/adapters/sgr_table.rb` (sequences for the layer), `carat/adapters/painted_rows.rb` (the layer as an input of a segment), `carat/adapters/frame_presenter.rb` (painting the line, the shape per mode), `carat/adapters/screen_presenter.rb` (the underline and the reset), `carat/use_cases/ex/set_command_handler.rb` (`:set cursorline`), `bin/carat.rb` (the `ensure`), `config/default.caratrc` and its generated mirror.
- Tests: `test/adapters_frame_presenter.rb`, `test/adapters_screen_presenter.rb`, `test/domain_theme.rb`, `test/domain_options_config.rb`, `test/domain_frame.rb`, `test/editor_search.rb` (`:set cursorline`), `test/editor_screen.rb`, `test/smoke_editor.rb`, and the tests whose cursor row changes group under the shipped option (`test/editor_syntax.rb`, `test/editor_explorer.rb`, `test/use_cases_plugin_syntax.rb`).
- Docs: `docs/compatibility.md`, `README.md`, `docs/architecture.md` sections 4, 7, and 8.2, `docs/codebase-map.md`, `docs/backlog.md`.
- Per key: no new allocation; a row is painted only when it was already repainted for the cursor's column or row.
