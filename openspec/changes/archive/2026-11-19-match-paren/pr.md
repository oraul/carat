feat(rendering): draw the bracket matching the cursor's in MatchParen

## Summary

Draws the bracket matching the one under the cursor in the MatchParen group, so the pair of `(`, `[`, and `{` is shown as Neovim shows it. Carat had a MatchParen theme row for every palette but no frame painted it.

---

## Changes

- Add the pair highlight to FramePresenter, drawing both brackets in the current window in normal, operator-pending, and visual modes, with the cursor on either bracket
- Search for the partner only in the rows the window shows, counting nested brackets of the kind, under a budget of 200,000 code points a frame, and draw nothing for an unmatched or off-screen pair or in a window with a closed fold
- Record the columns of a row's brackets in the painted row record so the row repaints when the pair appears, moves, or goes
- Add a table-driven frame presenter test for the pair cases and the budget, with its snapshot
- Document the differences from Neovim in the compatibility doc, and update the architecture, codebase map, and readme
- Add the screen-rendering requirement through the archived match-paren change

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the quality review, pass with no blocking findings and two advisory findings recorded in the findings file
- Run the benchmark review, pass with no blocking findings
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, and gates, all pass
- Run the OpenSpec validation of every spec, all 54 pass

---

## Notes

The two advisory findings (the pair search budget is checked after the row that crosses it is scanned, and the codebase map omits the folded-window pair) are recorded in the findings file for this change. The row that crosses the budget is still read, so a frame may read slightly more than 200,000 code points.
