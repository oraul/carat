feat(docs): flow paragraphs and quotes in the reading view

## Summary

The Markdown reading view now flows the lines of a paragraph into one row and the lines of a block quote into one quote row, so at 60 columns they wrap at the measure with the quote bar and the list indentation repeated on every row. Text wrapped by its author at another measure read ragged, short rows beside full ones and long quote lines wrapping without their bar.

---

## Changes

- Add the paragraph and quote flow to `MarkdownText.parse`: a heading, rule, list item, fence, table, blank line, indented code line, or a line ending in two spaces ends the flow
- Add the hanging prefix to wrapped rows, so a flowed quote keeps its bars and a list item's text hangs under its first word, while it takes less than half the width
- Fix a pipe line that opens another block right after a table being drawn as a table row; the table now ends there
- Fix `MarkdownText.parse` passing its row cap by the gap row and top border of a table that starts at the cap
- Change `FormatDocs#call` and its hover, completion, and reading callers to pass the raw and row caps instead of a bare bool
- Add `DocsText` support for extending a row's text and copying spans with a shift
- Add domain and reading-view tests for each new scenario and refresh their snapshots
- Document the flow in the README and the touched files in the codebase map, and sync the `markdown-reading` spec with two added requirements

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the quality review, pass with no blocking finding
- Run the benchmark review against main's recorded allocations and rounds, pass with allocations held
- Run make spec-validate after the archive, 53 items pass

---

## Notes

The flow also reaches the hover and completion floats, which share the parser. Lazy continuation lines, list item continuations, and the heading, code frame, and rule styling are left for markdown-reading-d. The review advisories on an indented code block inside a quote, the duplicated quote-marker scan, and a missing hover flow test are recorded in the change's findings file for the backlog.
