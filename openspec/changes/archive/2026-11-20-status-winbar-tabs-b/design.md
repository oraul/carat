# Design

## Context

`TabBar#paint_tab` and `Winbar#paint` choose a group per run of cells. `TabLineSel` is the mode pill's look (on-strong text on the blue accent, bold at 16 colors), which `test/domain_theme.rb` already keeps at contrast against `TabLine` and `TabLineFill` in every palette.

## Decisions

- No new highlight group or palette role: the accent is the pill's `TabLineSel`, so both themes, 16 colors, and NO_COLOR keep the contrast and bold checks that exist.
- The gem and the separator are constants of `TabBar` (the unicode glyph and the ascii one chosen by the set being `ascii`), as `Winbar` keeps its separators, rather than icon-table entries, which would widen the plugin-facing icon names for a private glyph.
- The gem takes the cell the leading space took on an unselected tab and the separator is a cell of every tab, so `tab_width` grows by the constant `FRAME_CELLS` and the overflow arithmetic is unchanged.
- The winbar's accent is on its last name, the innermost symbol or else the path, so the current window still shows focus without a symbol held; found by one pass over the held symbols, no allocation.

## Risks

A tab is two cells wider, so fewer tabs fit before the counts; the tests' overflow rows are recomputed.
