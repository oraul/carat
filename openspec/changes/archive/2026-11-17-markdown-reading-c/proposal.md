# Proposal

## Why

At 60 columns the reading view of a Markdown file (`<leader>dr`) shows each source line of a paragraph or a block quote as its own row, so text wrapped by its author at some other measure reads ragged: short rows beside full ones, and a long quote line wrapping without its bar. Three folds ride along: a heading, list item, quote, or fence line holding a `|` directly after a table is drawn as a table row (sprint-10 note 6), while GitHub's tables end where another block starts; `MarkdownText.parse` can pass its row cap by a gap row and a top border when a table starts at the cap; and the callers of `FormatDocs` pass a bare `true` or `false` to choose the caps. This is the user's now-request `markdown-reading` part c.

## What Changes

- Flow the lines of a paragraph into one row, and the lines of a block quote at the same depth and indentation into one quote row, so `wrap` cuts them at the measure; a heading, a rule, a list item, fenced code, a table, a blank line, or a line ending in two spaces (a hard break) ends the flow.
- Repeat a wrapped row's prefix on its continuation rows: the quote bars and indentation, and a bullet as two spaces, so a flowed quote keeps its bar on every row and a list item's text hangs under its first word; fenced code rows wrap as before.
- End a table's rows at a line that opens another block (a heading, a quote, a list item, a fence) even when it holds a `|`; that line is read as its own row.
- Keep the table's gap row and top border under the row cap, so `parse` never returns more than its cap.
- Pass `FormatDocs#call` the raw and row caps (`MarkdownText::RAW_LIMIT` and `ROW_LIMIT`, or the `READING_` ones) instead of a bool.

Out of scope: lazy continuation lines (a quote line followed by a line without `>`, or a list item followed by a plain line), which keep their own rows; a list item's continuation lines joining it; headings, framed code blocks, rules, and list gaps (`markdown-reading-d`); a backslash at a line's end as a hard break.

Roadmap: outside the roadmap order of `docs/architecture.md` section 12; it extends the delivered reading view at the user's request.

Assumptions: the documentation floats (hover and completion) share the reader, so a language server's paragraphs flow the same way; two lines join with one space, the second line's leading spaces dropped; a line ending in two or more spaces keeps the next line on its own row, as CommonMark's hard break; the hanging prefix is repeated only while it takes less than half the width, so a narrow float keeps the old cut; the allocations held are those `make bench SCENARIOS="lh j insert"` measures, which no markdown runs in.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `markdown-reading`: paragraphs and block quotes flowed to the measure with their prefixes on every row, and a table ended where another block starts.

## Impact

`carat/domain/markdown_text.rb` (the flow, the hanging prefix, the table's end and cap), `carat/domain/docs_text.rb` (a row's text extended, spans copied with a shift), `carat/use_cases/docs/format_docs.rb` and its callers `show_hover.rb`, `show_completion_docs.rb`, `toggle_reading.rb` (the caps passed); tests in `test/domain_markdown_text.rb` and `test/use_cases_toggle_reading.rb`, snapshots of the hover and completion tests where a long row now keeps its prefix; `docs/codebase-map.md`. No dependency, port, action, or binding is added.

- README.md: changed, the reading view flows paragraphs and quotes.
- docs/architecture.md: unchanged, its layers, ports, and the docs use cases are as they were; the change adds no file, port, or action.
