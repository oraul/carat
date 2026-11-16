feat(docs): add a reading toggle for markdown buffers

## Summary

Adds a reading toggle that shows a Markdown file as reading text, headings, emphasis, code, lists, and quotes laid out at a measure of at most 80 columns, and back to the file with the same key. No key showed a Markdown buffer as readable text, and the markdown reader drew its bullet, quote bar, and rule as box characters even under option.icons ascii, against the README's promise that ascii draws plain characters.

---

## Changes

- Add the docs.toggle_reading action, bound to leader d r in normal mode, which shows a .md or .markdown file in a scratch buffer titled with its path and, pressed again, returns to the file with its cursor where it was, refusing a buffer that is not Markdown or a source that was closed
- Bound the reading view at 262,144 bytes read and 10,000 rows kept, with escape sequences and controls dropped
- Change the markdown reader to draw its bullet, quote bar, and rule from the icon set, plain characters under ascii, so the hover and completion documentation floats follow the same set
- Remove MarkdownText.rows, which only a test called, and bring the MarkdownText module comment current with the spans, the icon set, and both sets of caps
- Add the markdown-reading spec and a hover-docs scenario for the icon set, archived with the change
- Add table-driven tests for the toggle and the ascii glyphs with their snapshots
- Document the action in docs/actions.md, the binding in config/default.caratrc and its generated mirror, the feature in the README, and the new files in the code map
- Record the sprint 9 queue, the groomed backlog, the review advisories, and the metrics and sprint rows of the merged changes

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and five advisories recorded in the backlog
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark against main's recorded figures, pass with no allocation or round regression
- Run make spec-validate after archiving, all 52 items pass
- Run make gates and make docs-lint before the push, both pass

---

## Notes

The reading view does not rewrap on resize or follow edits to the file; toggling twice refreshes it. Part b of the item, markdown-reading-b, is queued separately. The planning records carry the user-delegated queue decisions: lsp-incremental-sync joins sprint 9 as its second fix, spinel-notice is marked beyond the sprint, spinel-bump joins the pool, and the ux-pass findings are regrouped into ux-fixes-a and ux-fixes-b.
