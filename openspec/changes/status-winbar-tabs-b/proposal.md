# Proposal

## Why

The buffer tabs and the winbar kept their pre-Facet look: a selected tab differs from the others by color alone, tabs run together with no separator, and a winbar is one block in the accent. The user chose the Facet look for them (wave 2, split from status-winbar-tabs), so the tab line and the status bar speak one language and focus never rests on color alone.

## What Changes

- The tab of the current window's buffer starts with the gem `◆` (`*` under `option.icons ascii`) in the selected group, the others with a space, and every tab ends in a thin separator `│` (`|` under ascii) in `TabLine`; a tab is two cells wider. The modified mark keeps its one fixed cell, so tabs never shift on the first keystroke; the overflow counts and the tab-page numbers keep their groups.
- The winbar draws the leading space, the path, the separators, the outer symbols, and the pad in `TabLine`, the quiet dim; only the last name of the current window's winbar, the innermost symbol spanning the cursor row or the path when none does, is in the `TabLineSel` accent. The separators keep ` › ` and ` > ` under ascii.
- Both rows still read `Domain::Messages::NO_NAME`, and neither allocates, so `lh-winbar` is held.
- Tests: `test/adapters_tab_bar.rb` rows and groups for the gem, the separator, and the three icon sets; `test/editor_breadcrumbs.rb` for the accent on the innermost symbol only.
- Docs: README.md, `docs/compatibility.md`, and `docs/codebase-map.md` describe the look.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-tabs`: a tab's cells and the selected tab's gem and separators.
- `breadcrumbs`: the winbar's groups.

## Impact

- `carat/adapters/tab_bar.rb`, `carat/adapters/winbar.rb`, their tests, and the docs above. No new highlight group: the pill colors are `TabLineSel`, whose contrast against the row and the tabs `test/domain_theme.rb` already checks in every palette at 24 bits, 256 colors, and 16 colors, bold at 16 colors and under NO_COLOR.
- `option.showtabline` is left out (queued as `showtabline`); no assumption beyond that.
- README.md: updated, the winbar sentence.
