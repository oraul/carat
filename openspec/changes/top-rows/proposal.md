# Proposal

## Why

The user never noticed the buffer tabs: the selected tab is the terminal's own background in bold over a fill of nearly the same shade (one_dark's `PANEL_NC` against its background is about 1.1:1), so the current tab is told mostly by a faint color step. The modified mark's cell counts its glyph's width, so the tab's width can depend on the mark; the winbar joins symbols with a plain ` > ` and no accent marks the current window's; and `TabBar#put_number` repeats `StatusBar#digits_within`, the same digit fit kept twice. This is part a of the split of `top-rows` (sprint 3 item 1 of `docs/queue.md`), a user now-request; it delivers no new roadmap item of `docs/architecture.md` section 12 and refines the bars the roadmap already shipped. The rest of the item (the `:LspRestart` stale outline, the single owner of winbar rows, the scratch-split winbar row, the SymbolOutline comment) is queued as `winbar-outline`.

## What Changes

- `TabLineSel` is drawn bold in the palette's text-on-accent color over its blue accent, as the normal mode pill is, in every palette: the selected tab, the current tab-page number, and the current window's winbar stand out from `TabLine` and `TabLineFill` at 3:1 or more in background contrast at 24 bits and 256 colors, with another 16-color background, and by bold at every depth, so never by color alone.
- The selected tab's icon is drawn in `TabLineSel` instead of its file-icon group, so the accent block is unbroken.
- The modified mark takes exactly one cell: a tab's width no longer depends on whether its buffer is modified, and a mark glyph measured wider than one cell gives way to the ASCII mark.
- The winbar joins the path and the symbols with ` › `, and with ` > ` under `option.icons ascii`.
- `Frame#put_digits_within` is the one digit fit: the tab bar's counts and tab-page numbers and the status bar's numbers use it, and `TabBar#put_number` and `StatusBar#digits_within` are removed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-tabs`: the selected tab's icon in `TabLineSel`, and a new requirement for the modified mark's one cell.
- `breadcrumbs`: the ` › ` separator and its ASCII form.
- `color-themes`: the selected tab group's accent, its contrast against the tab row, and its bold.

## Impact

- Code: `carat/adapters/tab_bar.rb`, `carat/adapters/winbar.rb`, `carat/adapters/frame_presenter.rb` (passes the ASCII choice to the winbar), `carat/adapters/status_bar.rb`, `carat/domain/frame.rb`, `carat/domain/themes.rb`.
- Tests: `test/adapters_tab_bar.rb`, `test/editor_breadcrumbs.rb`, `test/domain_theme.rb`, `test/domain_frame.rb`, `test/adapters_screen_presenter.rb` (the tab groups' SGR).
- Docs: `docs/codebase-map.md` (the frame, tab bar, and winbar lines).
- README.md: changed, the winbar example reads `a.rb › Foo › bar` and the ASCII form is named.
- docs/architecture.md: unchanged, it names the painters and the groups, not their colors or the separator.
- Bench: `lh-winbar` and `lh` write the same cells as before; no string is built per frame (the separators and marks are constants).

Assumptions:

- "3:1" is the selected tab's background against the backgrounds of the other tabs and of the fill, as decorations are held to 3:1; the tab text already meets 4.5:1 through the existing text contrast check.
- "Never by color alone" is met by bold, which `TabLineSel` carries at every depth and `TabLine` does not; no extra glyph is added to the row.
- "The accent" is the palette's blue, the normal mode pill's, shared by `TabLineSel` everywhere it is drawn (tabs, tab-page numbers, the current winbar); no new highlight group is added.
- The ASCII separator follows `option.icons ascii` only, as the tab bar's icons do.

Out of scope: everything listed for `winbar-outline` above, new highlight groups (`WinBar`, `WinBarNC`), and the palettes' other colors (`carat-palette`).
