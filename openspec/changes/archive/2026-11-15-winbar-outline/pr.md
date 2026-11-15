fix(breadcrumbs): refresh the outline after a restart and fix scratch splits

## Summary

Makes the winbar outline follow a restarted language server and gives a split count from a scratch window exactly the rows it names. After :LspRestart the winbar kept the stopped server's symbols and never asked the restarted one for the same text, and four places restated which windows get a winbar, one of them reserving a winbar row a scratch split never shows.

---

## Changes

- Fix :LspRestart so it drops the held symbols and the record of the text last asked, and the restarted server is asked again at the first idle tick once ready
- Fix SplitWindow so a count from a scratch window that keeps the scratch buffer gives the new window that many text rows with no winbar row, under every breadcrumbs mode
- Refactor the breadcrumbs mode comparison into TabPage, with winbar? and a new winbar_with? that SplitWindow calls instead of restating the rule
- Change ArrangeView to record on each window whether it shows a winbar, and FramePresenter to paint the windows so marked instead of deciding again
- Add SymbolRequest forget and correct the SymbolOutline comment to say names are cut to 40 bytes
- Add test/editor_breadcrumbs.rb rows for the restart, the scratch splits, and winbar_with?, with the snapshot updated
- Document the touched files in docs/codebase-map.md, record the queue and the metrics history, and append three review advisories to docs/backlog.md

---

## Testing

- Run the security review of the committed diff, passed with no high, medium, or low finding
- Run the quality review, passed with no blocking finding and three advisories recorded in the backlog
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark comparison against main's recorded figures, passed
- Run make spec-validate after the archive, 51 passed and 0 failed
- Run make gates and make docs-lint before the push, all pass

---

## Notes

PinHover still splits with a count and then loads a scratch documentation buffer, so its count keeps a winbar row the window never shows; fixing it needs SplitWindow told the new window will be scratch, a signature change across five callers left for a follow-up. The brief's first finding no longer held as written on main, since stop already cleared the symbol request in flight; the defect fixed is that the last asked text and the held symbols survived the restart.
