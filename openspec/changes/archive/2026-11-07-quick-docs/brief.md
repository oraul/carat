# Brief

quick-docs: docs/queue.md item 1 as the planner wrote it (T5 user request, estimated large): K in normal mode asks the language server for hover documentation under the cursor and shows it in a scrollable float with markdown rendered (headings, emphasis, code spans, fenced code highlighted with the existing highlighter, lists), a key pins it into a split that survives closing the float, Esc or moving the cursor closes the float; the text is untrusted (escape sequences stripped, size and nesting capped, hostile markdown never crashes or hangs the editor); no per-key cost when no float shows. Continuous loop. Security review is never skipped.

Plan notes:
- docs/backlog.md 'Wrapped markdown rows break inside their own prefix' (about line 1823): now folded into quick-docs. Fix it there with a table row in test/domain_markdown_text.rb and remove the entry; its current 'Queued in `completion-tidy-b`' line is out of date.
- docs/backlog.md entries from 'The completion resolve timeout restarts with every pick' through 'CompletionMenu#chosen repeats the chosen index' and 'The resolve cases repeat their setup three times' (about lines 1829 to 1865): change 'Queued in `completion-tidy-b`' to 'Queued in `completion-docs-tidy`'.
- docs/backlog.md 'Completion resolve state outlives a switch of completion language' (about line 1871, the security Low (3)) and 'A server crash during a resolve has no test' (about line 1877): add 'Queued in `completion-docs-tidy`'.
- docs/backlog.md 'The tools test's wait for the runner's stage fails silently' (about line 1883): add 'Queued in `check-runner-safety`', alongside completion-docs retro note.16.
- docs/backlog.md 'merge-gate-integrity's open quality advisories' (about line 1727): its queue reference moves from pinned-main to item 45, the batch of backlog items.
- The completion-docs retrospective proposals are placed only in the queue text (note.16 in check-runner-safety, note.17 in review-scope, note.18 in merge-gate-tidy); they need no backlog entry.
- The check-isolation overrun (1,683,378 total tokens against the 1.2M medium budget) is recorded in the queue Decisions.
- Package step: `sh tools/run_state.sh history` adds completion-docs' row (#75) to docs/metrics.tsv, and build/plan/queue.md (17,368 bytes, budget 17,369) replaces docs/queue.md. I removed the old build/plan/backlog.md because there are no new backlog entries.
