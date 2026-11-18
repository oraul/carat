
### The guide-colors retro entries are folded twice into the backlog

- Location: `docs/backlog.md:8396`, `:8401`, `:8406` repeating `:8377`, `:8382`, `:8387`; the `:8361`-area facet-palette and sprint-17-records entries (sprint-18-records quality review, raised twice)
- Why: the three guide-colors retro entries came in twice from facet-palette's findings file, and with the facet-palette and sprint-17-records entries make four near-same notes on advisory-only rounds.
- Fix: list the second copies as duplicate and merge the advisory-only notes into one in the next `groom.txt`.

### Two security entries stay open though #214 fixed them

- Location: `docs/backlog.md:8392` and `:8416` (SECURITY_MARK misses unmarked security entries); `tools/run_state.sh:454`
- Why: both are carried open though b5b0aec (#214) widened SECURITY_MARK, so the backlog overstates open security work.
- Fix: list both as fixed by b5b0aec in the next `groom.txt` after checking its tools-test cases.

### Folded backlog entries lack the blank lines around their headings

- Location: `docs/backlog.md:8372`, `:8396`, `:8460` (`:8461` in the second review pass) and most added entries (sprint-18-records quality review, raised twice)
- Why: the entries lack the blank line after the heading and before the next heading, the same format defect groom's fold keeps producing.
- Fix: fold into the existing "Groom's fold keeps producing format defects" entry, or have groom normalize blank lines when folding.

### The backlog-lane sprint size entry repeats the drift entry

- Location: `docs/backlog.md:8361` and `:8520` (`:8521` in the second review pass); `tools/docs_lint.sh:22`, `docs/codebase-map.md:55` (sprint-18-records quality review, raised twice)
- Why: "The code map says the backlog lane's sprint holds 0 to 2 items" repeats part of "Doc comments and map entries drift".
- Fix: merge the two at the next grooming.
