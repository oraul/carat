feat(docs): frame code and keep quoted code rows in the reading view

## Summary

The reading view now keeps an indented code block inside a quote as its own rows, reads a line's quote markers with one scanner shared by every reader, and draws fenced code blocks in a frame beside styled headings. An indented block in a quote flowed into one quote row and lost its line breaks, and three separate marker scans could cut a joined line at a different byte than the one that classified it. This delivers 2 of the user's 4 reading-view parts, headings and framed code blocks, with the quote fixes.

---

## Changes

- Add `MarkdownText.markers`, one allocation-free scan of a line's leading spaces and quote markers packed in an Integer, which `flow_key`, `marker_end`, and `block` all read, and drop the indentation cap that never ran.
- Fix an indented code line inside a quote so it keeps its own row instead of flowing into the quote row, the four-space check counting the spaces after the markers.
- Add framed fenced code blocks to the reading view, drawn by `wrap` after highlighting with a border from the icon set at most the width wide, long lines going on in the next framed row and the code's spans kept on the code.
- Change `FormatDocs` to take a framed flag that `ToggleReading` sets and hover and completion docs leave off, so their two-column code is unchanged.
- Add `test/domain_markdown_text.rb` rows for a two-line indented block in a quote, a line mixing spaces and markers cut at one byte by all readers, and a heading and a framed code block with their styles, and `test/use_cases_toggle_reading.rb` rows for the framed code's spans.
- Update the markdown-reading spec with the marker scan, the indented code in a quote, and the framed code, and document them in the README and the code map.
- Record the next feature queue, the metrics history row, and a review finding and the plan's backlog entries in this change's findings file.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings.
- Run the quality review, pass with no blocking findings and 3 advisories: the design's minimum frame measure corrected, the duplicated cutting walk dropped as style, and the double marker scan recorded as a finding.
- Run the checker stages dev-build, test-build, test-run, diagnose, bench-budget, tools-test, docs-lint, gates, and metrics, all pass.
- Run the benchmark review against main's recorded figures, pass.
- Run `make spec-validate` after the archive, 53 of 53 pass.
- Run `make gates` and `make docs-lint` before the push, both pass.

---

## Notes

A quote with one to three spaces before its first marker no longer reads an indentation level in, as CommonMark reads it; no test held the old reading. A code line too long for its frame breaks at a character, as an unframed code row already does. The quality advisory on the duplicated cutting walk in `frame_line` is dropped as a style point, and parse still scanning a line's markers twice is recorded as a finding for a follow-up.
