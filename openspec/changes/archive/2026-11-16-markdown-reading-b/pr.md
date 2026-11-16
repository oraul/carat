feat(docs): draw markdown tables aligned in the reading view

## Summary

Draws a Markdown table in the reading view as aligned columns inside box borders, each column aligned as its separator row says and its cells wrapped when the table is wider than the window. At 60 columns the view showed a table as its source, raw pipes and the separator row included, so a README's option tables read worse than the file itself. Two folds ride along: the reading toggle reads a line crossing the 262,144-byte cap only to the cap, and the code map names ToggleReading among the callers of FormatDocs.

---

## Changes

- Add table drawing to MarkdownText: a header row, a separator row, and the rows after it become columns in box borders with the header parted by a rule, aligned left, center, or right by the separator cells' colon markers.
- Add plain ASCII borders of plus, minus, and pipe characters under option.icons ascii, so the view stays ASCII.
- Add cell wrapping for a table wider than the measure: the widest columns narrow first and their cells wrap at a space, or on a character for a longer word, each row growing to its tallest cell.
- Change FormatDocs to pass the width to the reader, so the documentation floats draw tables the same way.
- Fix ToggleReading to gather a line crossing the 262,144-byte cap only to the cap, cut on a character boundary, instead of copying it whole.
- Add domain and use case tests with snapshots of a three-column table at 100 and 60 columns with each alignment, the ASCII borders, and the over-cap line.
- Document the tables in the README and the markdown-reading spec, and name ToggleReading in the FormatDocs entry of the code map.
- Add markdown-reading-c, the paragraph and quote flow with the bool-literal fold, at the head of the feature pool for sprint 11, and rename the later markdown-reading part to markdown-reading-d.

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass.
- Run the quality review, passed with no blocking finding and five advisories.
- Run the benchmark review, allocations held at lh 26.0, j 27.0, and insert 26.0.
- Run make spec-validate after the archive, 53 items pass.

---

## Notes

The paragraph and block quote flow and the bare bool literals callers pass FormatDocs are left for markdown-reading-c. Tables inside a block quote or a list item, and a table with too many columns to give each two cells at the measure, stay as their source lines. Three advisories are recorded as findings: the parsed rows can pass the row cap by one or two before wrap re-caps them, the documentation floats lack a table test, and split_cells copies a cell a character at a time. Two duplication advisories, the repeated line-end lookup and the expected tables repeated across the two tests, are dropped as style.
