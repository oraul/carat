# Design

## Context

`Domain::MarkdownText.parse(text, set, raw_limit, row_limit)` reads markdown line by line into a `DocsText` (rows, spans, fence languages and block numbers), and `wrap(doc, width, set, row_limit)` wraps each row at the width with its spans; `UseCases::FormatDocs#call(state, text, width, reading)` parses, tokenizes fenced code, and wraps, for the documentation floats and for `UseCases::ToggleReading`, which shows the result in a scratch buffer at the window's width capped at 80 columns. A table line today goes through `block` and `inline` like any paragraph line, so its pipes and its separator row stay. `ToggleReading#text_of` joins the buffer's lines while the gathered text is at most `READING_RAW_LIMIT` bytes, appending each line whole.

## Goals / Non-Goals

**Goals:** a table laid out once, aligned and bordered within the measure and the icon set, in the one pass `parse` makes; the reading text gathered only to its cap; the map current.

**Non-Goals:** cell markup styles; tables nested in quotes or lists; a live relayout on resize (the toggle rebuilds the view, as before).

## Decisions

### 1. `parse` lays tables out, so it takes the width

A table's column widths depend on every row and on the measure, and its rows must never be cut again by `wrap`. `parse` gains a `width` argument (`FormatDocs` passes the one it gives `wrap`): on a line outside fenced code that holds `|`, `table` looks at the next line; when it is a separator row (only spaces, `|`, `:`, and `-`, holding a `|` and a `-`, each cell `:?-+:?`) whose cell count equals the header's, and the measure gives each column at least two cells (`5 * columns + 1 <= width`), the header and the following rows that hold `|` are read into a flat array of cells (`columns` per row, short rows padded, long ones cut) and drawn as finished rows of at most `width` cells, which `wrap` then leaves whole. Otherwise `table` answers -1 and the line is read as before. Rows are added only while the document is under its row cap, and the table's source rows are counted against it too. Alternative: mark table rows in `DocsText` and lay them out in `wrap`; rejected because it needs a new per-row kind that `FormatDocs`'s highlighter and every `DocsText` reader would have to skip, for no gain, since `parse` already runs with the width known.

### 2. Cells are split, read out, and measured once

`split_cells` cuts a stripped line at each `|` not escaped as `\|`, dropping one leading and one trailing pipe, each cell stripped. Each cell's text goes through `inline` with a scratch `DocsText`, so emphasis, code spans, links, and escapes read out as in a paragraph; the scratch's spans are dropped (Non-Goals). Widths are `DisplayWidth.text_width`, so a wide character takes two cells.

### 3. Narrowing caps the widest columns

The room for text is `width - (3 * columns + 1)` (a border and two spaces per column, one closing border). When the natural widths fit, each column keeps its own (at least two). Otherwise a binary search finds the largest cap `L` with the sum of `min(natural, L)` within the room, and the room left goes a cell at a time to the capped columns in order, so short columns keep their width and the widest give way first, in `columns * log(widest)` steps rather than a cell at a time. A cell wraps at its last space within its column, or on a character when a word is longer, and a table row is as tall as its tallest cell, the other cells padded with blank lines.

### 4. Borders come from the icon set

`box(set)` answers the eleven border pieces: corners, tees, the cross, the horizontal and the vertical line, `┌┬┐├┼┤└┴┘─│` for `unicode` and `nerd`, `+` for every joint, `-`, and `|` for `ascii`, as `bullet`, `bar`, and `rule` choose theirs. Each line is the vertical, then per column a space, the piece padded to the column's width by its alignment (center putting the odd cell on the right), a space, and the vertical. The top border, the header, a rule under it when body rows follow, the body, and the bottom border make the table; a blank row parts it from text above it, as any block.

### 5. The gathering moves into the reader

`MarkdownText.gather(lines, limit)` joins the lines by newlines up to `limit` bytes: a line wider than the room left is cut to it, stepping back off continuation bytes so the cut falls on a character boundary, and nothing more is read. `ToggleReading` calls it with the source's lines and `READING_RAW_LIMIT`, so the use case keeps its one public method and the domain test proves the cut. A line under the room is appended whole as before, so the common case allocates nothing more.

### 6. Allocations

Nothing here runs on a key other than `<leader>dr`, `K`, or a completion's documentation, so the `lh` 26.0, `j` 27.0, and `insert` 26.0 allocations per key `make bench` measures are untouched.
