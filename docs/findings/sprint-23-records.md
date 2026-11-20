### groom folds none/None placeholder lines from findings files
- Location: docs/backlog.md:922 (a stray None in the LIMIT-doubles entry), :9956 and :9962 (none and None after a doubled blank line); tools/run_state.sh groom
- Why: the placeholder lines of syntax-tidy.md, contributor-tier-medium.md, and metrics-header-fix.md were folded verbatim into the backlog.
- Fix: have groom skip a findings file holding only none or None and drop a trailing none or None line, with a tools-test case; remove the three lines in the next records change.

### Removal of the byte basename heading dropped the gateway File.basename calls
- Location: docs/backlog.md:230, the removed heading '## Three copies of the byte basename'; carat/adapters/json_rpc_language_gateway.rb (File.basename calls near :394, :408, :425)
- Why: syntax-tidy left the gateway calls out of scope and they still stand, so the removal dropped that part of the entry.
- Fix: re-add a short entry for the gateway's File.basename calls, or record why they need no change.

### Two queue items do not cite the headings folded for them
- Location: docs/queue-backlog.md:17 (groom-findings-refs, Pool 5) and :18 (records-bench-skip, Pool 6)
- Why: the headings 'groom folds findings entries that still name the findings files it deletes (sprint-22-records retro note 4)' and 'A records-only change still runs the benchmark and rebuilds the lane (sprint-22-records retro note 3)' are not in their Backlog lists, so those deliveries are not handed them and leave them open.
- Fix: add each heading to its item's Backlog list in the next plan.
