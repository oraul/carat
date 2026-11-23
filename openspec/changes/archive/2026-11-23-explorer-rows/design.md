# Design

## Context

`Tree#build` listed the root as its first node (depth 0) and every entry below it at depth 1 or more; `Node#root?` guarded the keys. The marked file's line carried the `current` icon in its marker cell and nothing marked the row itself. The frame presenter knows two row layers for a window (the cursor line's and the sidebar's) and nothing a plugin chooses.

## Goals / Non-Goals

**Goals:**
- A tree that starts at the root's entries.
- The current file's row drawn as `docs/design.md` section 8 says.

**Non-Goals:**
- The bold label, the faint tree guides, the right-aligned git state, and the other selection marks (`one-accent`).

## Decisions

- The root node is dropped, not hidden: `build` walks the root at depth 0, `Node#root?` is removed, and the guards in the plugin go with it. `parent_row` answers -1 for a depth-0 entry. A tree with no entry (an empty folder) has no row under the cursor, so `a` creates in the root. Alternative: keep a hidden root node and skip it when drawing, which would shift every row index by one between the model and the buffer for no gain.
- The highlight is the host's, asked for by row. A plugin's tokens carry only syntax and icon groups, which have no background and cover text cells only, so a full-width fill cannot come from `tokenize`. The new request `mark_scratch_row(title, row)` stores `Buffer#marked_row`, and `FramePresenter#paint_marked_row` fills the window's cells of that row with `PmenuSel` and the first cell with `PmenuMarkSel`, both on the sidebar layer (their own backgrounds win over it). Both groups exist and have their themes already (the finder's selected row), so no group, theme, or layer is added. Under NO_COLOR only the bar is drawn, as the finder's spans do. Alternative: a `sign` on the row, rejected because a plugin can place signs only on a listed buffer and a scratch buffer shows no sign column.
- `set_scratch_lines` clears the mark, since the row it named may hold another entry; the explorer marks again after every refill (`mark_current`). The row key of the presenter's cache includes whether the row is marked, so a moved mark repaints exactly the two rows.
- The bar glyph is the `current` icon the explorer already writes in the marker cell, now `▎`; the presenter recolors it and draws no glyph of its own, so the ascii set shows `|` and the nerd set its private use glyph.

## Risks / Trade-offs

- The current row's icon loses its file-type color to the fill. A cell holds one group; a layer for a selection background would keep it but add a layer to every theme table.
- A minor API bump (2.17); a plugin written against 2.16 loads unchanged.
