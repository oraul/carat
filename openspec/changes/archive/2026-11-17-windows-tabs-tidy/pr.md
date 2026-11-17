fix(windows): refuse the minimum float offset and tidy the scroll code

## Summary

Refuses a float offset at the integer minimum and tidies the windows and scrolling code: one scroll trait as an overridden predicate, one name per half-page scroll target, a single clear of the previous window in CloseOtherWindows, and nine comments re-wrapped to their file's width. FloatSpec bounded offsets through Integer#abs, which overflows at the integer minimum, so a plugin's float could open at an offset the plugin-windows spec refuses (security Low, confidence 4), and the other items were backlog findings in the same code.

---

## Changes

- Fix FloatSpec.offset_refusal to compare each offset against both bounds instead of through abs, so the integer minimum is refused as a row and as a column like any other offset out of range
- Change ActionHandler#breaks_insert into the predicate breaks_insert?, false in the base class and overridden to true by ScrollHandler, so no subclass writes a base class trait after super; the dispatcher reads the predicate and scroll keys still break the insert session
- Rename the half-page scroll targets to half_page_down and half_page_up, the suffixes of their actions, in ScrollHandler, ScrollWindow, and ScrollRequest's comment
- Remove the second clear of tab.previous from CloseOtherWindows, which BufferList#close_window already clears for each window it closes
- Change nine comments under carat/ to wrap at their file's width
- Add tests for the integer minimum refused as a row and as a column and for :only and the window-only key leaving no previous window, with their snapshots
- Document breaks_insert? in the ActionHandler and ScrollHandler entries of the codebase map
- Add the change's three non-blocking review findings to its findings file and record the backlog lane's plan and metrics history

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding and nothing blocking
- Run the quality review, pass with no blocking finding and three advisories recorded in the findings file
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark review against main's recorded figures, pass with nothing blocking
- Run make spec-validate after archiving the change, 53 items pass

---

## Notes

The quality review found that the archived tasks and design describe a BufferList#close_window clear of tab.previous when it equals the new current window, which did not ship, so closing into the previous window still leaves it named and the new comment in close_other_windows.rb overstates this; that finding, an 83-column comment left in scroll_request.rb, and the doubled bound test in float_spec.rb are recorded in the findings file for a follow-up. The split remainder buffer-commands-tidy (the doubled digits? helper, a long zero-padded buffer number answering E86, and BufferRequest's current target) is left in the pool.
