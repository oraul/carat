### Groom's listed proof accepts a heading as a bare substring of the queue item (`groom-proof` security Low (5))
- Location: tools/run_state.sh:2387 (item_lists)
- Why: item_lists accepts the heading as a bare substring of the queue item, so a planner `listed` line for a short heading such as `## Foo` passes when the item only quotes a different, longer heading such as `### Foo bar`; a security entry can then leave the backlog without its merged item ever naming it, the proof this change set out to require.
- Fix: Require a bounded match: no `#` before it, and after it the closing quote the planner writes (`Backlog: "### title"`), a comma, or the end of the item; or match the quoted form `"` H `"`. Add a tools-test case refusing a shorter heading that prefixes a quoted longer one.

### Groom's duplicate guard lets a security entry without a `security <severity>` marker leave (`groom-proof` security Low (3))
- Location: tools/run_state.sh:422 (SECURITY_MARK)
- Why: The guard used to refuse any entry mentioning security and now refuses only text matching its severity marker, so a security entry written without it (an older entry, or one transcribed from a periodic note recorded as `High (8) file:line ...` under the note kind `security`) can leave as a `duplicate` without a listed item or a fixing commit. The design accepts the risk, since findings deliver-change.js hands over carry the `security <severity>` prefix, limiting the exposure to entries written some other way.
- Fix: Also treat an entry as a security entry when its heading or Location line carries a severity and confidence pair, `(High|Medium|Low) \([0-9]+\)`, or when it came from a security note; or make the planner's sprint mode write `security <severity>` into the heading of every security entry it adds, so the marker the guard reads always exists.

### Groom's listed proof still accepts a comma after an unquoted heading (`groom-proof` security Low (2))
- Location: tools/run_state.sh:2410 (item_lists)
- Why: item_lists accepts a comma after a heading that no double quote or backtick opens, so a short heading `## Foo` still counts as listed when an item mentions a longer heading `## Foo, bar` bare or in single quotes, and a security entry could then leave the backlog without its merged item naming it. It predates the change and is narrower now: the planner's double-quoted form is closed, so the residual needs a bare or single-quoted mention of a backlog heading that is the exact prefix of another heading followed by a comma.
- Fix: Accept a bare heading only at the end of the item, or treat a single quote like the other quote characters; stricter, require the planner's quoted form (Backlog: "H") outright. Add a tools-test case with a bare `## Foo, bar` against `## Foo`.

### Groom's guard against a `#` before a listed heading has no test (`groom-proof` quality advisory)
- Location: tools/run_state.sh:2406 (item_lists)
- Why: Untested branch: item_lists' guard against a `#` before the heading (a `## y` heading inside a quoted `### y` one) has no tools-test case; only the guard after it is exercised, so a regression in it would pass the suite.
- Fix: Add a listed case whose item quotes `### ...` for the same `## ...` heading, listed unquoted at the item's end or before a comma so the guard alone refuses it.

### exception_item now counts a wrapped `beyond the sprint` mark without a test (`groom-proof` quality advisory)
- Location: tools/run_state.sh:2127 (exception_item)
- Why: Untested branch: exception_item now reads the item through queue_items, which joins continuation lines, so a `beyond the sprint` mark inside a first parenthesis wrapped onto the next line now counts as an exception in review-due and the sprint row, where main read the first line only; no review-due case pins the new behavior.
- Fix: Add a review-due tools-test case whose item's parenthesis wraps before the mark.
