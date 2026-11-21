# Backlog: carat/domain/docs_text.rb

## Documentation formatting scans every token quad per row

- Where: `tokens_of` in `carat/domain/docs_text.rb` line 111 (per row, from styles) and `copy_spans` at line 83 (per wrapped piece), at the `quick-docs-styles` change. Quality advisory in `quick-docs-styles`.
- Why it matters: formatting costs rows times spans, up to 100 rows times thousands of token quads, on every completion selection change.
- Fix outline: walk the quads once with a cursor, since `wrap` appends them in row order, or keep a per-row start index.
- Category: editor
- Added: 2026-11-09

## Findings of markdown-reading-c after its package step

- quality advisory docs/findings/markdown-reading-c.md:29 the package commit 1fc49d8 appended the three git-signs-status-b retro entries (check pass cost, resumed run 0 tokens, quality first pass) a second time, lines 1-14 already holding them, and left no blank line before :15 and :29; fix: drop the second copy at :29-42 and put one blank line between entries
- quality advisory carat/domain/docs_text.rb:63 simple and elegant: last_line= stores an alias that parse then grows in place (markdown_text.rb:108-118, the flowing and flowing_row state), cleverness the flow does not need, and the archived tasks.md 1.1 names a DocsText#extend_last that does not exist; fix: one DocsText#append_to_last(text) that replaces the last row with the joined string, dropping
- quality advisory carat/domain/markdown_text.rb:920 under the ascii set a text row starting with ' ' (a literal pipe line or a narrow table's source) is read as a quote bar prefix, so hang now repeats ' ' on every continuation row of a plain line; fix: take the hanging prefix from the parsed row kind (record the prefix length per row in DocsText at parse) rather than re-reading the text, with an as
- quality advisory docs/findings/markdown-reading-c.md:29 docs currency: the three pipeline findings of lines 1-14 (check pass cost, resumed-run tokens, quality first pass) are appended a second time; fix: drop lines 29-42
- quality advisory carat/domain/markdown_text.rb:108 tests beside every behavior change: the -2 path also stops a narrow table's header from joining a paragraph line right before it (key -1 while source), but only the wide table has that case (test line 248); fix: add a test/domain_markdown_text.rb case at width 15 of 'text' directly followed by a narrow table, expecting 'text' its own row
- quality advisory carat/domain/markdown_text.rb:82 naming: the bool local source says nothing of what it tracks (inside the lines of a table too narrow to draw); fix: rename it narrow_table
- Also: carat/domain/markdown_text.rb, test/domain_markdown_text.rb
- Category: editor
- Added: 2026-11-17
