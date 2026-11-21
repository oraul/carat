# Backlog: carat/domain/markdown_text.rb

## The documentation formatter's periodic findings

- Where, at df4654c: `carat/domain/markdown_text.rb` line 299 (`inline` drops emphasis markers inside a code span; `test/domain_markdown_text.rb` line 80 asserts the garbled span), line 66 with line 76 and `carat/use_cases/docs/format_docs.rb` line 19 (the two-column fence indent spelled three times), line 202 (`heading?` and `heading_text` repeat a scan), line 35 (`rows` used only by its test, module comment at line 9 and `docs/codebase-map.md` line 602 stale), line 387 (`wrapped` mutates and returns `out`); `carat/domain/docs_text.rb` line 111 and line 83 (rows times quads, the existing scan entry); `carat/domain/buffer.rb` line 85 (`styles` a bare `Array[untyped]` shared by reference from `show_completion_docs.rb` line 111, `show_hover.rb` line 94, `pin_hover.rb` line 57, which also repeat the float buffer build); comment wraps at `show_completion_docs.rb` line 25, `show_hover.rb` line 21, `pin_hover.rb` line 15. Periodic quality, one blocking. Queue item `hover-tidy`.
- Why it matters: `**kwargs` in a code span shows as kwargs; the indent must agree in three places for tokens to land; formatting is quadratic on every selection change.
- Fix outline: keep marker bytes literal inside a code span and fix the row, one `CODE_INDENT`, one heading helper, drop `rows` into the test, a `SyntaxLines` list and one `Buffer.from_docs` (then drop the `styles` line of `UNTYPED_SHARED` in `test/lint.rb`, which exempts it from the shared list rule), rewrap the comments.
- Also: test/domain_markdown_text.rb, carat/use_cases/docs/format_docs.rb, docs/codebase-map.md, carat/domain/docs_text.rb, carat/domain/buffer.rb, test/lint.rb
- Category: editor
- Added: 2026-11-09

### MarkdownText.split_cells copies each cell a character at a time

- Location: carat/domain/markdown_text.rb:219
- Why: each cell is built by one byteslice per character, an allocation per byte on every table row parsed for the reading view and the floats.
- Fix: track the cell's start byte and byteslice the whole run at each unescaped pipe.
- Category: editor
- Added: 2026-11-17

### MarkdownText cell_lines repeats the wrap's cut-finding loop
- Location: carat/domain/markdown_text.rb:414 and :794
- Why: cell_lines repeats the cut at the last space or on a character boundary that wrap writes out with spans and columns, two copies to keep in step.
- Fix: pull out the shared cut-finding loop, or say in a comment why the two stay apart.
- Category: editor
- Added: 2026-11-17

### A pipe line right after a table is drawn as a table row
- Location: carat/domain/markdown_text.rb:177
- Why: table rows go on through any line holding a pipe, so a heading, list item, quote, or fence line with a pipe directly after a table is drawn as a row, while GFM ends the table where another block starts. Folded into markdown-reading-c.
- Fix: also stop at a line that opens a block (#, >, a list marker, a fence), with a test.
- Category: editor
- Added: 2026-11-17

### MarkdownText.parse finds a line end inline beside line_end
- Location: carat/domain/markdown_text.rb:75 and :192
- Why: two copies of one byteindex lookup.
- Fix: call line_end in parse.
- Category: editor
- Added: 2026-11-17

### MarkdownText.parse runs the marker scan twice per line
- Location: carat/domain/markdown_text.rb:114 (parse calling flow_key, then marker_end at line 123 or block at line 133)
- Why: each line's quote markers are scanned once in flow_key and again in marker_end or block, a repeated byte walk per row on reading views of up to 262,144 bytes, though the shared scanner was meant to read a line once.
- Fix: compute markers(line) once in parse and pass the packed scan to flow_key and block, marker_end becoming marker_stop(scan).
- Category: editor
- Added: 2026-11-17

### Cut_point and carat/domain/markdown_text.rb (sprint-20 sweep quality, process_runner.rb:155)

- Location: `carat/drivers/process_runner.rb:155`
- Why: cut_point and carat/domain/markdown_text.rb:366 (gather) each walk back over UTF-8 continuation bytes to cut text before a character, while Domain::Utf8 holds only the forward boundary
- Fix: add one Utf8 helper (the largest offset at or below a limit that splits no character, at most three bytes back) and use it in both
- Also: carat/drivers/process_runner.rb
- Category: editor
- Added: 2026-11-19
