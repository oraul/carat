# Proposal

## Why

At 60 columns the reading view of a Markdown file (`<leader>dr`) shows a table as its source: raw pipes, ragged columns, and the `|---|:---:|` separator row, so a README's option tables read worse than the file itself. Two folds ride along: the reading toggle gathers the file's lines up to the 262,144-byte cap but copies a line that crosses the cap whole, so a one-line megabyte file is copied in full only to be cut by the reader; and the code map's `FormatDocs` entry names its callers without `ToggleReading`. This is sprint 10's fifth change, the user's now-request `markdown-reading` part b; the paragraph and quote flow is part c.

## What Changes

- Draw a Markdown table (a header row, a separator row of `-` cells with optional `:` markers, and the rows holding a `|` after them) in the reading view as aligned columns inside box borders (`┌─┬─┐`, `│`, `├─┼─┤`, `└─┴─┘`), the header parted from the body by a rule, each column aligned as its separator cell says (`:--` or `---` left, `:-:` center, `--:` right), the cells' inline markup read out as elsewhere.
- Under `option.icons ascii` the borders are `+`, `-`, and `|`, so the view stays ASCII.
- When the table is wider than the measure, narrow the widest columns first and wrap their cells at a space (or on a character when a word is longer than the column), each table row growing to its tallest cell.
- Gather the file for the reading view only up to the cap: a line crossing the 262,144-byte cap is read only to it, cut on a character boundary.
- Name `ToggleReading` among the callers in the map's `FormatDocs` entry, and the tables in the `MarkdownText` entry and its test's.

Out of scope: flowing paragraphs and block quotes to the measure, and the bare bool literals callers pass `FormatDocs` (part c, `markdown-reading-c`); tables inside a block quote or a list item, which stay as their source lines; a table too narrow to give each column two cells at the measure (more than (width - 1) / 5 columns), which also stays as its source lines; the markup styles (strong, code, links) inside a cell, whose text is kept but whose spans are not.

Roadmap: outside the roadmap order of `docs/architecture.md` section 12; it extends the delivered reading view at the user's request.

Assumptions: the documentation floats (hover and completion) share the reader, so a table in a language server's documentation is drawn the same way; the rows of a table end at a blank line or a line holding no `|`; a row with fewer cells than the header is padded with empty cells and one with more is cut to the header's count, as GitHub's tables do; a separator row whose cell count differs from the header's makes no table; the allocations held are those `make bench` measures, `lh` 26.0, `j` 27.0, and `insert` 26.0, as the brief gives them (`docs/metrics-feature.tsv` records `insert` 32.0 from the metrics build, which this change does not move either).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `markdown-reading`: tables drawn aligned in borders within the icon set and the measure, and the over-cap line gathered only to the cap.

## Impact

`carat/domain/markdown_text.rb` (the table layout and the gathering), `carat/use_cases/docs/format_docs.rb` (the width reaches `parse`), `carat/use_cases/docs/toggle_reading.rb` (gathers through the reader); tests in `test/domain_markdown_text.rb` and `test/use_cases_toggle_reading.rb`; `docs/codebase-map.md`. No dependency, port, action, or binding is added, and nothing runs per key unless a docs float or the reading view is built, so the `lh`, `j`, and `insert` allocations hold.

- README.md: changed, the reading view draws tables.
- docs/architecture.md: unchanged, its layers, ports, and the docs use cases are as they were; the change adds no file, port, or action.
