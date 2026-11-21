# Design

## Context

`TabBar#paint_tab` writes the gem in the first cell of the selected tab and a space in the others, so every tab is `FRAME_CELLS` wide. The selected group `TabLineSel` already has the accent background and bold in every theme, and `tab_glance` holds it at 3:1 from `TabLine` and `TabLineFill`.

## Decisions

### Keep the cell, drop the gem

The first cell becomes a space for every tab, in the tab's group. The width, `FRAME_CELLS`, and the overflow arithmetic stay, so the counts and the cut tests do not move. Alternative: remove the cell; rejected, since it changes every width and the run selection for no gain, and the selected background reads better with a cell of padding.

### Tab-flow rows

Without a gem the separators are the only tab marks left in row 0. `top_row` blanks every separator character (`|` and `│`) in the row and squeezes, so a name holding its own `|` would lose it (no flow names such a file, and the separator test lives in `adapters_tab_bar`).
