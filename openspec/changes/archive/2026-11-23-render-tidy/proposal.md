# Proposal

## Why

The terminal never had bracketed paste turned on, so a paste arrived as typed keys: a pasted Escape left insert mode and a pasted colon opened the command line, so pasted text could run `:w!` or any command (a security Low). Beside it, `FramePresenter`, `TabBar`, and `StatusBar` carry seven small defects and untidy spots the sprint reviews queued as `render-tidy`.

## What Changes

- Change `ScreenPresenter`: turn bracketed paste on when the screen is entered and off when it is left (`ESC [ ? 2004 h` and `l`), the off sequence first in the leave sequence so the cursor reset still ends it.
- Change `KeyDecoder`: the text between `ESC [ 200 ~` and `ESC [ 201 ~` is decoded to codes with the new `Key::PASTED` flag, never to keys: printable characters, a tab, one newline for CR, LF, or CRLF; `Esc` and every other control byte are dropped; a paste cut short by a read waits for its end mark, and `flush` leaves it.
- Change `HandleKey#call`: a pasted code is never looked up in a keymap; insert mode inserts it (a newline breaks the line as Enter does), the command line takes its printable characters (a newline is dropped, so a paste never runs the command), and no other mode does anything with it.
- Fix `FramePresenter`: a row painted after the frame's highlighting budget stopped is stored with a stamp no frame draws, so the next frame paints it again with its matches.
- Refactor `FramePresenter`: the buffer row, the window's currency, and the number's highlight group are arguments of `paint_row`, `paint_matches`, and `paint_pair`, not the instance variables `@row_of`, `@current`, and `@number_hl`; the hit-enter prompt and the start screen share one clear of the layout; the tab row is asked through the new `TabBar#showing?`.
- Refactor `StatusBar`: drop the unused plugin API require, name the lsp state parameter `lsp_state`, and `@owners` is `@plugin_index`.
- Document the paste in `docs/compatibility.md` and `docs/codebase-map.md`.

Not fixed here: the two decode headings (queued as `render-tidy-b`), and the walk of matches left of the horizontal scroll, recorded in `docs/findings/render-tidy.md` with its reason.

Assumptions: pasted text in normal and the other modes does nothing, where Neovim puts it in; a later change may add that. A pasted tab is a literal tab character whatever expandtab says.

## Capabilities

### New Capabilities

### Modified Capabilities

- `key-input`: bracketed paste decodes to text codes.
- `screen-rendering`: bracketed paste is turned on at enter and off at leave.

## Impact

- Code: `carat/adapters/screen_presenter.rb`, `key_decoder.rb`, `frame_presenter.rb`, `tab_bar.rb`, `status_bar.rb`, `carat/domain/key.rb`, `carat/use_cases/handle_key.rb`.
- Tests: `test/adapters_key_decoder.rb`, `editor_insert.rb`, `adapters_screen_presenter.rb`, `adapters_frame_presenter.rb`, `adapters_tab_bar.rb`, and their snapshots.
- Docs: `docs/compatibility.md`, `docs/codebase-map.md`.
- README.md: the paragraph after Ctrl-S names the paste.
- docs/architecture.md: unchanged, its ScreenPresenter entry already names bracketed paste and the file is at its size budget.
- CLAUDE.md: unchanged, no process or rule changed.
- No edit of `tools/rules.sh`.
