# Brief

buffer-substitute: docs/queue.md item 1 as the planner wrote it (T5 user-approved roadmap feature, estimated large, due under the every-three rule). The next item is already decided, so no planner decision is needed unless the size rule requires a split (if so, deliver ex ranges with :s, :& , & and g& first, and queue :g, :g!, :v right after). Security review is never skipped..

Plan notes:

- Split: this change delivers ex ranges (%, ., $, a number, '<,'>) with :s and its flags and replacement characters, plus :&, & and g&. :g, :g! and :v are queued as item 1, buffer-global. Their docs/compatibility.md rows and tests are not part of this change.
- The queue item's acceptance named the `n` scenario, which tools/metrics.sh:30 does not record. Measure against lh 27.0, j 28.0, insert 35.0 and undo 53.0 objects per key at e20c83c.
- docs/backlog.md:29 'The ex grammar parses no ranges' is removed by this change once ranges land. If '<,'> is left out, narrow the entry to that instead.
- docs/metrics.tsv: run `sh tools/run_state.sh history` in the package step to append the pipeline-speed-b row (PR 49, merged e20c83c, rework 1, quality first pass 0, CI 3.5 minutes, estimated medium, 309,581 output and 1,476,371 total tokens, 62.0 minutes).
- Add the five entries of build/plan/backlog.md to docs/backlog.md (periodic review findings at e20c83c, each with a 'Queued in' line).
- docs/backlog.md 'Queued in' pointers to update: lines 303, 309, 477, 489 and 525 change from pipeline-speed-c to pipeline-durability; line 495 changes to agent-inputs; line 323 stays in pipeline-speed-c. Add 'Queued in implement-contracts' to the entry at 527, 'Queued in pipeline-speed-c' to 533, and 'Queued in merge-gate-integrity' to 539.
- Commit build/plan/queue.md as docs/queue.md. It is 21,599 bytes, down from 28,136, and every one of its 22 items carries a tier and a size.
