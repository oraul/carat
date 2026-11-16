### MarkdownText.parse overruns its row cap with a table

- Location: carat/domain/markdown_text.rb:182 and its top border at line 295
- Why: with the gap set at row_limit - 1 rows, the blank row plus the unconditional top border push the parsed DocsText one or two rows past row_limit; wrap re-caps the output so nothing shows, but parse breaks its own at-most-row_limit contract.
- Fix: add the gap row and the top border only while doc.count is below row_limit, as draw_table already does for the body and the bottom border, with a test at the cap.

### Documentation floats draw tables with no test or spec saying so

- Location: carat/use_cases/docs/format_docs.rb:38, test/adapters_hover.rb, README.md, openspec/specs/markdown-reading/spec.md
- Why: parse now draws tables at the width for the K and completion documentation floats too, but the spec and README name only the reading view and no hover test shows a table, so the float behavior is unproven.
- Fix: say in the README sentence on the floats and in the spec that documentation floats draw tables the same way, and add one float row with a table to test/adapters_hover.rb.

### MarkdownText.split_cells copies each cell a character at a time

- Location: carat/domain/markdown_text.rb:219
- Why: each cell is built by one byteslice per character, an allocation per byte on every table row parsed for the reading view and the floats.
- Fix: track the cell's start byte and byteslice the whole run at each unescaped pipe.

