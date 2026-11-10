# Design

## Context

`FramePresenter#paint_window` paints a file window's rows; a row is repainted only when `PaintedRows#same?` finds an input changed (the line by identity, scroll, gutter, number, sign, selection, cursor column, layer, syntax entry, search stamp). Leading whitespace is painted as blank cells by `paint_text`. Floats take `paint_float_row` and the start screen paints over the window, so neither passes through the row loop; plugin windows (the explorer, pick lists) do, with a buffer whose `scratch?` is true. Highlight ids are literal integers in `Highlight`, the UI groups first; `Themes::GROUPS` gives each its roles. Allocations per key are 27.0 (`lh`), 28.0 (`j`), and 35.0 (`insert`) on `main`, and must not change.

## Goals / Non-Goals

**Goals:**

- Guides with no allocation per key, and no repaint of a row whose guides did not change.
- The guides computed from the visible rows only, plus the search for a blank run's neighbors.

**Non-Goals:**

- A guide model in the domain that use cases read; nothing but the presenter needs the guides.

## Decisions

### `Adapters::IndentGuides` measures a window, then paints rows

A plain class beside `PaintedRows`, built by `FramePresenter` like its painted-row records (it is the presenter's own scratch state, not shared). Before a file window's rows are painted, `measure(buffer, top, height, cursor_row, current)` walks the visible lines once: each line's indent is read byte by byte (a space is one column, a tab runs to the next multiple of `tabstop`, anything else ends it; a line of whitespace only is blank), into a preallocated `Array[Integer]` that grows only when a taller window appears. A forward and a backward pass give each blank row the smaller of its nearest non-blank neighbors' indents, searching past the window's edges for at most 1000 lines (`NEIGHBOR_LIMIT`). The scope column is the deepest level below the cursor row's indent, `((indent - 1) / width) * width`, and the scope runs over the contiguous visible rows around the cursor whose indent passes it. `paint(frame, row, i, col, width, left)` then puts the glyph at each level of row `i` inside `[left, left + width)`, in `IblScope` at the scope column of a row inside the scope and `IblIndent` elsewhere.

Alternative: decoding the line through `LineCache` to find the indent; rejected, since the bytes answer it without touching the cache and a whitespace prefix needs no width table.

### The guide key is an input of a row

`PaintedRows#same?` and `store` take one more integer, the row's guide key: 0 with no guide, else the carried indent and the scope column packed into one integer (`indent * 2^21 + scope + 1`, the indent capped below 2^20). A blank row whose neighbor changed, or a row entering or leaving the cursor's block, is repainted; a `j` inside one block repaints nothing more than today. The settings that change every row at once (the switch, the glyph, the level width) are compared once per frame and, when they differ from the last frame's, every painted segment of both frames is forgotten, as a resize does.

Alternative: packing the glyph and the width into the key too; rejected, since the key would pass 64 bits and these change only when options do.

### Order of the layers in a row

The guides are painted after the syntax tokens and before the search matches and the selection, so a match or a selection over leading whitespace still shows its group, and before the cursor-line `lift`, which raises the guide cells onto the cursor-line layer like any other cell.

### The groups and their colors

`IblIndent` and `IblScope` are UI groups 49 and 50, after the status bar's, and every id after them moves by two, as the status bar's groups moved the syntax ids; every reference is by constant or name. `IblIndent` takes `FAINT`, the role of `Whitespace`, which indent-blankline links it to; `IblScope` takes `DIM`, the role of `LineNr`, which indent-blankline's scope links to. Both are decorations, held to 3:1 on the background, on the cursor line, and in a float, which these roles already pass in all four palettes.

### The options

`indentguides` is a `bool` member (fresh false, shipped true) and `indentguides_char` a `String` member read from `option.indentguides.char`, checked as one UTF-8 character whose `DisplayWidth` is 1 and whose code point is not a control. `Options#guide_code` answers the code point drawn: 124 (`|`) when `icons` is `ascii` and the character is outside ASCII, else the character's own.

### Bench

The shipped configuration turns the guides on, so `lh`, `j`, and `insert` measure them on (the code text is indented four columns, two levels on every row); `lh-noguides`, `j-noguides`, and `insert-noguides` turn them off after the configuration is read.

## Risks / Trade-offs

- [The measure walks every visible row each frame] → it reads only the leading bytes of each row with `getbyte`, allocation free, about 60 rows at the bench's 60-row screen; the bench figures are the check.
- [A long run of blank lines] → the neighbor search stops at 1000 lines, so a blank row more than 1000 lines from text shows no guides.
- [Renumbered ids] → a plugin resolves groups by name at activation, and only the count test names the numbers.
