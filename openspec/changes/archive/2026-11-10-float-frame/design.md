# Design

## Context

See proposal.md, Why. A float is a `FloatWindow` whose window rectangle is its text area, placed by `ArrangeView#place_floats` through `FloatWindow#place`, with the box (border included) answered by `box_top`, `box_bottom`, `box_left`, and `box_right`. `FramePresenter#paint_float_row` paints the text and calls `paint_border_row`, which writes the rounded glyphs and the title from the corner; `paint_notice_row` repeats the border with an ASCII form under `NO_COLOR`.

## Goals / Non-Goals

Goals: padding in every float, Neovim's `winborder` with an ASCII form, a centered title in `FloatTitle`, one border painter, and no added allocation per key in `lh-float`, `finder`, or palette filtering.

Non-Goals: placement (margins, centering, resize), new plugin API members or requests, focus marks, menu columns (proposal, Out of scope).

## Decisions

### The box: a stored edge and a fixed padding

`FloatWindow` gains a pinned member `edge`, the rows the border takes on each side, 0 or 1, set at every `place` from the spec's `border` and whether `option.winborder` draws an edge (`none` does not); it starts at the spec's `edge` so a float not yet placed answers its box as before. The padding is `FloatWindow::PAD`, one column on the left and the right of every float, bordered or not: the box's horizontal side is `edge + PAD`, its vertical side `edge`. Padding rows above and below were weighed and left out: the palette, the key hints, and the completion popup would lose a row each on a small screen, and Facet's padding is the cell between the line and the text.

`place` cuts the width to `cols - 2 * (edge + PAD)` as it cut it to `cols - 2 * edge`, so a box still never leaves the screen. The spec's `width` stays the text's width, so no caller and no plugin computes the box. The alternative, a `pad` member on `FloatSpec` (and so on `FloatOptions`), would change a plugin API record with required members, the decision this split leaves to `float-placement`.

### The border style resolved once per frame

`Domain::BorderStyle` holds the five style names and, for a style and an ASCII flag, one frozen array of six code points (the four corners, the horizontal, the vertical): `single` `┌┐└┘─│`, `double` `╔╗╚╝═║`, `rounded` `╭╮╰╯─│`, `solid` blanks, and the ASCII form `++++-|` for the three with lines. `none` answers the blank set, used only by the notices, whose boxes keep their edge. `FramePresenter#call` looks the array up once per frame (a constant, nothing allocated) from `options.winborder` and `@plain || options.icons == "ascii"`, and both painters read it.

### One border painter

`paint_edge(frame, r, left, last, top, bottom, hl)` draws one row of a box's border from the resolved glyphs; `paint_border_row` (floats, in `FloatBorder`) and `paint_notice_row` (notices, in `FloatBorder` or `Normal` when plain) call it. The notice titles stay at the left as nvim-notify places them.

### The centered title

On the top edge the title takes the cells between the corners: `room = last - left - 1`; the title with a blank on each side, cut to the room, starts at `left + 1 + (room - width) / 2`. Its width is `DisplayWidth.text_width`, which walks bytes and allocates nothing. It is drawn in `FloatTitle`, a new UI group: `Title`'s blue and bold over the float's background (`FLOAT`), so the edge reads as one surface; the contrast test covers it with every text group. The group is appended after `IblScope`, the last UI group, so the syntax, file-icon, and markup groups move up by one and their ids in snapshots with them.

### Padding painted with the row

`paint_float_row` paints the text or blanks the text area, blanks the padding columns, then fills the whole inner row once with the row's group (`NormalFloat`, `Pmenu`, or `PmenuSel`), then the documentation styles over it; the second fill of the old code goes.

### Callers that size boxes

The completion popup's column moves one more column left so its text stays under the typed word, and its documentation float stands at the popup's box edge (two more columns). The palette centers its box `width + 2 + 2 * PAD` wide; the key hints cut their width to `screen_cols - 2 - 2 * PAD`. The finder's list is `cols - 6` wide, or `(cols - 11) / 2` with the preview at column `width + 6`, `cols - width - 11` wide, so both boxes keep one column from the edges and between them.

## Risks / Trade-offs

- Every float's text moves one column right, and every snapshot of a float changes; the snapshot diffs are read in full.
- A third-party plugin that tiles floats overlaps by two columns until it leaves room for the padding. No such plugin exists in the tree; the API comment states it, and `float-placement` decides the API.
- The new group shifts the token group ids; plugins name groups, never ids, so the API is unaffected.

## Measures

`make bench SCENARIOS="lh-float finder palette"` against main's figures: allocations per key and rounds equal (task 5).
