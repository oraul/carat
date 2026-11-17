# Design

## Context

`FollowPalette#show` opens the palette at any screen of 8 columns or more, its float text `FloatWindow.text_room(cols, winborder)` capped at 90 cells: 2 cells at 8 columns under an edged border, 4 under `option.winborder none`. `rows` pads the description to `label_room(width)`, the name to 30 cells when `named?`, and the key to 12 cells, then cuts the row to the width. Below 62 cells `label_room` is `width - 12`, so at 12 cells or fewer the label has no cell left and the cut row shows only the start of the key; at 13 and 14 cells it has 1 and 2 cells, of which `kept_bytes` keeps at most one character.

## Goals / Non-Goals

Goals: a row shows its label at every width the palette opens at; `styles` takes only what it reads; `pad` pads once; the map names the calls the file makes. Non-goals: other column widths, a shrinking key column, the name's threshold.

## Decisions

- A predicate `keyed?(width)`, true when `width - KEY_WIDTH >= KEY_WIDTH`: the key's column is kept only when the label keeps at least as many cells as the key. Below it `label_room` is the whole width and `rows` appends no key. At 24 cells and up nothing changes. Alternative rejected: shrinking the key to half the width, which at the narrowest float (2 cells) leaves the label one cell, which `kept_bytes` fills with nothing but the padding space, so the label still vanishes.
- `named?` implies `keyed?` (62 cells against 24), so `styles`, which places the name's column from `label_room`, needs no change beyond the dropped parameter.
- `styles(top, lines, width)`: the cut mark is never styled, and the limits of the marks come from `kept_bytes`, which does not depend on the mark, so the parameter goes rather than being read.
- `pad` pads in one step with `ljust` to `cell.length + width - used` characters when the cell is narrower than the width, so the cells it lacks are added as spaces at once.

## Risks / Trade-offs

- Between 13 and 23 cells a row that showed a cut label and its key now shows the label alone. Accepted: on a float that narrow the label is what tells the entries apart, and the palette is filtered by name, so the key is the extra.

## Testing

`test/editor_palette.rb` gains a table, "A palette at the smallest screen shows a label", over the 8-column screen under both borders and narrow widths around the threshold: each row's first cells are the label of `window.split` and the key shows only at 24 cells and up. The existing narrow palette, cut, key, and frame checks hold. `make bench` holds the recorded allocations.
