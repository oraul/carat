# Proposal

## Why

The selected tab still draws a gem (`◆`, `*` under ascii) although the user's decision is that tabs show only the modified mark. Under ascii the gem and the modified mark are both `*`, and the tab-flow test needs about 60 lines of heuristics to tell a gem, a separator, a name, and a mark apart.

## What Changes

- `TabBar` no longer writes a gem: the leading cell of every tab is a space, so every tab keeps its width and the overflow arithmetic is unchanged. The selected tab is told apart by `TabLineSel` (the accent background and bold, held at 3:1 and bold by `tab_glance` in `test/domain_theme.rb`); the separator and the fixed-width modified mark stay.
- `GEM` and `ASCII_GEM` are removed.
- `test/editor_tab_flows.rb` drops `strip_tab_cells`, `counter_end`, and `tab_boundary?`: row 0 is compared as the squeezed text, with the tab separators and the leading blank cells squeezed out by a one-line replacement of the separator characters.
- Docs: the buffer-tabs spec, `docs/compatibility.md`, and the code map.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-tabs`: MODIFIED requirement "A tab per listed file buffer".

## Out of scope

- The tab-page numbers, the overflow counters, and the window winbar keep their groups.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: the groups of a tab do not depend on a theme, a color depth, or NO_COLOR (the group id is the same; the driver maps it), so the frame-row tests cover every icon set once and the per-theme contrast and bold are proved by the existing `tab_glance` test over every palette on both backgrounds, which covers 256 and 16 colors; NO_COLOR keeps the bold group and prints no gem.

## Impact

- README.md: changed, the winbar paragraph no longer says the selected tab starts with a gem.
- docs/architecture.md: unchanged, it does not name the gem of a tab.
- docs/codebase-map.md: area 13, the `tab_bar.rb` line.
- docs/compatibility.md: the Buffer tabs row.
- Performance: one write less per painted tab; `lh` paints no tab row.
