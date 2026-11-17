### ExRange resolve answers E16 for an implicit offset Neovim reads (vim-line-commands-b quality)
- Location: carat/domain/ex_range.rb:151
- Why: resolve now answers E16 for a range piece Neovim reads as an implicit offset (`.5`, `$ 1`, `. 5`), where it answered Not implemented before, since unread? counts only + - ; / ? ' and bare digit runs; a behavior change without its test.
- Fix: treat an address base (. or $) followed by digits or blanks as unread too, and add a domain_ex_range row for `.5d`.
### The planner runs on a first queue item already placed and estimated (secret-patterns retrospective)
- Location: `tools/run_state.sh` plan-needed
- Why: secret-patterns' planner changed no decision (its queue only removed the delivered item and restated the Decisions) yet cost 11,077 of 127,363 output tokens (8.7 percent) and 12 of 112 tool calls (10.7 percent).
- Fix: plan-needed answers 0 for a delivery of the first queue item with its estimate set and no pending retro or overrun note, while plan-apply still removes the delivered item; accepted when such a run records planned=0 and no plan phase.

### A current area pack is scouted again for a missing location (secret-patterns retrospective)
- Location: `.claude/workflows/deliver-change.js` scout reuse
- Why: the build-and-ci pack, current at 8b54500, was discarded because its Locations line lacked `tools/scan_text.sh`; the scout then spent 42,854/20, 33.6 percent of output tokens and 1.34 times implement's 31,927, against 8.7 to 19.4 percent in the last medium backlog rows.
- Fix: reuse a pack current at the run's commit and add only the named locations; accepted when such a delivery spends under 15 percent of output tokens on the scout phase.

### The medium merge call cap overruns on CI waiting alone (secret-patterns retrospective)
- Location: `.claude/workflows/deliver-change.js` CALL_CAPS
- Why: a green first-pass CI with rework 0 made 16 merge calls over the medium cap of 14 with ci_wait_calls 6 and CI 8.4 min (record-squash-commit 14, markdown-reading-d 13 at the same wait count), and the overrun note then asks the planner to re-estimate a change whose size did not cause it.
- Fix: size the merge cap by CI waits, not by the estimate; accepted when the next three medium runs with first-pass green CI of 7 to 12 minutes record merge calls at or under the cap and no merge overrun note.
