# Design

## Context

`Domain::MarkdownText.parse(text, set, raw_limit, row_limit, width)` reads markdown line by line into a `DocsText`: each line outside code and tables goes through `block` (its quote bars, indentation, heading, rule, and bullet read, its inline markup taken out) and becomes one row; `wrap(doc, width, set, row_limit)` then cuts each row at the width on its own, a continuation row starting at column 0 with no prefix. So a paragraph written on two lines is two rows, and a quote line wider than the measure loses its bar after the first row. A table's rows go on through any line holding `|` (`table`, the loop at :174 and its break at :177), and `table` adds its gap row and `draw_table` its top border with no test against the cap (:182 and draw_table's first line). `UseCases::FormatDocs#call(state, text, width, reading)` picks the caps from a bool that its three callers pass as literals.

## Goals / Non-Goals

Goals: a paragraph and a block quote flow as one text at the measure; a wrapped quote keeps its bars; a table ends where another block starts; `parse` keeps to its cap; the callers of `FormatDocs` name the caps they want.

Non-Goals: lazy continuation lines and list item continuations (they keep their own rows); headings, code frames, rules, and list gaps (`markdown-reading-d`); a trailing backslash as a hard break.

## Decisions

### 1. `parse` joins a flowing line onto the row before it

`parse` keeps a `flow` key: -1 when the last row cannot take a continuation, else the depth and indentation of the paragraph or quote line that made it (`depth * (NEST_LIMIT + 1) + indent`). A new helper `flow_key(line)` reads a line's leading spaces and `>` markers as `block` does and answers -1 for a blank line, a heading, a rule, or a list item, else the key. A line outside code whose key is not -1 and equals `flow`, with no gap since the row before, is joined: its text after the markers goes through `inline` at the column after the last row's text and a space, its spans landing on that row, and `DocsText#extend_last(text)` appends `" " + text` to the last row. Every other row sets `flow` from its own key; code, tables, and a line ending in two spaces set it to -1. Joining in `parse` rather than `wrap` keeps one source of truth for what a row is, and `wrap` already cuts any row at the width. Alternative: join in `wrap` by marking rows as continuations; rejected as it needs a per-row kind that `FormatDocs`'s highlighter and every reader would have to know.

### 2. A continuation row repeats the prefix

`wrapped` reads the row's prefix (`prefix_size`) and, for a row outside fenced code whose prefix takes fewer than half the width's cells, starts each continuation row with it, a bullet replaced by two spaces (`hang`). The continuation's used cells start at the hang's, and its spans are copied with the hang's length as a shift: `DocsText#copy_spans` gains a `shift` argument, 0 for the first piece. Code rows keep the old cut, so a long code line still wraps at column 0 and the highlighter's columns are untouched. Alternative: repeat only quote bars; rejected because a nested quote's indentation and a bullet's text would then start at a different column on every continuation row.

### 3. A table ends at a block opener

The row loop of `table` breaks at a line with no `|` or one that `opens_block?`: after its leading spaces, a `>`, a heading marker run, a fence, or a list marker (`-`, `*`, `+` and a space). The line is then read by `parse` as any other line. A separator row is never a block opener (it holds `|` and its `-` runs are followed by `|` or `:`, not a space), so `|---|` keeps working.

### 4. The table keeps to the cap

`table` adds its gap row only while `doc.count < row_limit`, and `draw_table` its top border likewise, as its middle and bottom borders already were; so `parse` returns at most `row_limit` rows.

### 5. `FormatDocs` takes the caps

`call(state, text, width, raw_limit, row_limit)`: `ShowHover` and `ShowCompletionDocs` pass `Domain::MarkdownText::RAW_LIMIT, Domain::MarkdownText::ROW_LIMIT`, `ToggleReading` the `READING_` pair. The caps are domain constants already, so the call reads as what it chooses and no new type is needed.

### 6. Allocations

Nothing runs per key unless a docs float or the reading view is built; `extend_last` builds one string per joined line where the old path built a row. `make bench SCENARIOS="lh j insert"` is compared with main's recorded figures.
