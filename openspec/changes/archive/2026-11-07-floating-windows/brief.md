# Brief

floating-windows: docs/queue.md item 1 as the planner wrote it (T5 roadmap feature, estimated medium): windows that float over the layout, which the completion list and the documentation popups need. From the approved UI plan: a float spec value (anchor, position, size, border and title, z order), a float layer per tab page, focus into and out of a float, painting by z with the covered rows invalidated and no scroll region under a float, Esc closing the topmost, and plugin host requests to open, move, and close a float with a minor API bump. Acceptance as the planner wrote it, plus: no change to allocations or time per key with no float open, and with a 60 by 15 float open lh under 20 microseconds and at most 3 extra allocations per key. Continuous loop: no planner decision is needed. Security review is never skipped.

Plan notes:

- Package step: `sh tools/run_state.sh pending` still lists periodic-review-caps (merged as 948721e, #66). Its row goes into docs/metrics.tsv with `history`, and this plan's queue is committed in the same step.
- Nothing new for docs/backlog.md. The three periodic-review-caps advisories are already there: 'The security reviewer's not-run order reads reversed', 'The periodic review caps design names the wrong owner of the overrun notes', and 'The periodic review's missed check accepts either kind's values'. Queue item 42 now refers to them.
- periodic-review-caps' quality-blocking note.1 (CLAUDE.md:206 and README.md:184) was fixed before its merge: quality passed at f8141546abe6. Nothing is placed for it.
- The estimate is now large rather than the queue's medium. The workflow should store `large` so the budget and the history row measure the run against 2.5M.
- build/plan/queue.md is 17,263 bytes, under the 17,369 limit for docs/queue.md. No build/plan/backlog.md or goals.md was written.
