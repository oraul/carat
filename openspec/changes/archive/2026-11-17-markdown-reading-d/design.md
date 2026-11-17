# Design

## Context

`Domain::MarkdownText.parse` reads each line outside code and tables through three scans of its leading spaces and `>` markers: `flow_key` (the flow key, -1 at four or more spaces before the first marker, an indent cap after that check that can never run), `marker_end` (any run of spaces and `>` bytes, for the text a joining line appends), and `block` (the bars, indentation, and rest of a row). Spaces after a marker are swallowed by all three, so `>     x = 1` reads as a plain quote line and flows. Fenced code rows are `"  " + line`, a `@markup.raw.block` span from column 2, the fence's language and block number on the row; `FormatDocs` tokenizes each such row past its two-column indent, then `wrap` cuts rows at the width (a code row on a character).

## Goals / Non-Goals

Goals: one scan for the three readers; an indented code line inside a quote kept on its row; the dead cap gone; fenced code framed in the reading view; a heading and a framed block each proven in its style.

Non-Goals: rules and list gaps (`markdown-reading-e`); frames in the documentation floats; heading underlines or per-level styles.

## Decisions

### 1. One scan, packed in an Integer

`MarkdownText.markers(line)` reads the leading spaces; under four, it reads each `>` and the spaces after it, the content's indentation being those spaces less one, and stops after a marker followed by four or more (an indented code line in the quote, whose next `>` is text). With no marker the indentation is the leading spaces, and four or more leading spaces read no marker (CommonMark's indented code). It returns the byte after the scan, the depth capped at NEST_LIMIT, and the indentation capped at 15, packed as one Integer (`(stop * (NEST_LIMIT + 1) + depth) * 16 + indent`) read by `marker_stop`, `marker_depth`, and `marker_indent`: allocation free on every line, and no array to destructure (docs/spinel-notes.md). `flow_key` answers -1 at an indentation of four or more, else `depth * 2 + indent / 2` (indent / 2 is 0 or 1, so no cap), `marker_end` is `marker_stop`, and `block` draws its bars and `min(indent / 2, NEST_LIMIT)` indentation levels from the same value. Alternative: a `Data` value per line; rejected as an allocation per line for three integers.

### 2. The frame is drawn by `wrap`, after highlighting

`wrap(doc, width, set, row_limit, framed)` with `framed` draws each run of rows of one fenced block (blank rows between them included) as a frame: a top border, each code line cut into pieces of the inner width on a character boundary, each piece `side + " " + piece + padding + " " + side`, then a bottom border, the inner width the block's widest line capped at `width - 4`. The spans `parse` and `FormatDocs` added (the `@markup.raw.block` run and the language's tokens, both from column 2) are copied by `DocsText#copy_spans` with the shift that keeps them on the code, the frame's two-column left side standing where the indent stood. Drawing in `wrap` keeps the tokenizer reading the code alone, never the padding or the right side, and a long line's pieces keep their tokens. A measure under six columns (FRAME_MIN) keeps the indented rows. Alternative: draw the frame in `parse` as tables are; rejected as `FormatDocs` tokenizes after `parse` and would read the frame as code.

### 3. Who frames

`FormatDocs#call(state, text, width, raw_limit, row_limit, framed)` passes the flag to `wrap`: `ToggleReading` passes true, `ShowHover` and `ShowCompletionDocs` false, so the hover-docs spec's two-column code holds.

### 4. Headings

A heading already reads as its text with a `@markup.heading` span from its prefix, which the reading view draws; the change adds the reading-view test row and no drawing.

## Risks / Trade-offs

- A quote with one to three spaces before its first `>` no longer reads an indentation level in; CommonMark agrees, and no test held the old reading.
- A code line cut inside a frame breaks at a character, not a space, as an unframed code row already does.
