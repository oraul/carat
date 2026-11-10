# Brief

definitions: docs/queue.md item 1 as the planner wrote it (T5 user request, estimated large): gd jumps to the definition of the symbol under the cursor through the language server (opening the target file, with a jump-list entry so Ctrl-O returns), and a peek key shows the target's source in a float without leaving the buffer (Esc closes it); several targets show a short pick list; no server or no answer gives Neovim's message; requests asynchronous and cancelled when stale; targets outside the project or untrusted paths are refused or opened read-only per the existing file-access rules; allocations per key unchanged. Bring main in before the check if the base is stale (word-completion went red in CI on a nine-merge-old base). Continuous loop; the file finder follows. Security review is never skipped.

Plan notes:

- docs/backlog.md has 3 entries, about lines 3138 to 3156, from word-completion's quality advisories at 8f486e0 that have no 'Queued in' line: 'Keyword completion skips the word right after the cursor on an empty prefix', 'Typing after Ctrl-P selects the farthest match' and 'No test pins that typing with no popup costs nothing more'. Add 'Queued in `completion-tidy`.' to each, matching the 5 entries above them.
- docs/queue.md item 7 `run-resume` now includes word-completion's retrospective proposal about a stale base. Its backlog entry (if any) should name run-resume. The brief already asks this run to bring main in before the check if the base is stale.
- The word-completion row (#88, merged a4832db52c54, 1,438,486 total tokens, 102.0 min, estimate large) is still pending in run state. This change's package step adds it to docs/metrics.tsv with `sh tools/run_state.sh history`.
- Removed the old build/plan/backlog.md left from an earlier plan. No new backlog entries: every finding was placed in the queue.
- build/plan/queue.md is 17,151 bytes, under the docs/queue.md budget of 17,369 in tools/docs_lint.sh.
