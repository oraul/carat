# Brief

completion-request: docs/queue.md item 1 as the planner wrote it (T5 user request, estimated large): the language server source of the completion popup, asynchronous, debounced while typing, stale requests cancelled, results bounded and their text untrusted (escape sequences stripped, lengths capped), with the folded fix that a failed initialize must not mark the server ready. After this change comes merge-gate-integrity as the one pipeline change, then completion-docs and quick-docs; the main session moves the pr-footer item out of the queue to the backlog as not fixable from the repository (7 of 7 pull requests got the footer at creation with the attribution settings on main; only the immediate removal remains). Continuous loop. Security review is never skipped.

Plan notes:

- Fold into this change: periodic quality at 5722559, carat/adapters/input_controller.rb:61. Language services are polled only when no key arrives, so a completion reply would show only after the user pauses. Accepted when a reply that arrives between keys fills the popup, with a test.
- docs/backlog.md:839 (pull requests created with a session-link footer): update the entry to 7 of 7 footers at creation with main's attribution settings, not fixable from the repository, only the immediate removal left. The pr-footer item is removed from the queue.
- docs/backlog.md:1391 (the Frame comment gives four integers per float): remove the entry, which periodic quality at 5722559 found fixed (carat/domain/frame.rb:27 now gives ten, matching FLOAT_STRIDE). float-tidy no longer lists the stale Frame comment.
- docs/backlog.md:1043 (the map's Designs lines omit the last features): add completion to area 17 (docs/codebase-map.md:595) and area 13 (:453), plus diagnostics-display's paint_diagnostic in area 13, and one area 17 Flow sentence for the completion source (periodic quality at 5722559, docs/codebase-map.md:557).
- docs/backlog.md:1517 (ControlText.cleaned is public with a flag argument): extend it with RAW_LIMIT declared between methods and with without_sequences, sequence_end, and string_end left public (periodic quality at 5722559, carat/domain/control_text.rb:27).
- Add the nine entries in build/plan/backlog.md to docs/backlog.md.
- Queue changes: completion-tidy is item 23 and holds periodic quality findings at editor_assembly.rb:324, mode.rb:17, handle_key.rb:200, handle_key.rb:114, and codebase-map.md:133 (one of them blocking). content-gate-gaps takes the PR tools' Low (5). merge-gate-integrity takes the merger hook Medium (6) and the forged guard Low (4).
- build/plan/queue.md is 17,362 bytes against the 17,369 budget, so any later addition must fold text.
