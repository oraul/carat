# Brief

parameter-info: docs/queue.md item 1 as the planner wrote it (T5 user request, estimated medium), the second of the two serialized changes the user asked for; the queue holds after it. In insert mode inside a call's parentheses, a small float above the cursor shows the signature from the language server's signatureHelp with the current parameter marked, follows the cursor across arguments, and closes outside the call or on Esc; requests are asynchronous, debounced, and cancelled when stale; the text is untrusted (escape sequences stripped, length capped); no per-key cost when no float shows and allocations per key unchanged. No planner decision is needed. Security review is never skipped.

Plan notes:

- Acceptance for parameter-info: an answer to an older signatureHelp request that arrives after a newer request is sent is never shown, with a test row for that order. The hover path fails this check (periodic quality blocking at carat/adapters/json_rpc_language_gateway.rb:674, queued in hover-tidy). The gateway already cancels in three copies (backlog entry 'The gateway cancels a request in three copies'); a fourth copy would add to that entry.
- Estimated large, not the queue's medium: the language server feature rows #72, #75, and #76 ran 1.44M to 1.87M total tokens.
- docs/backlog.md:759 (the content gate binary-file entry): raise it to periodic security Medium (7) at b0dd342 (tools/gates.sh:179). It is queued in content-gate-gaps.
- docs/backlog.md:1627 (the tabstop copies entry): the repeat_last.rb line moved from 105 to 104 (periodic quality at b0dd342).
- docs/backlog.md:1491 (the ControlText entry): remove without_sequences from Where and Fix outline, because MarkdownText.rows (carat/domain/markdown_text.rb:34) now calls it.
- docs/backlog.md:1805 (the ProcessRunner entry): add carat/drivers/runtime_queue.rb, which builds ServiceMessage without requiring it. Still present at b0dd342.
- docs/backlog.md:1423 (the LspStart and LspRestart register entry): still present at b0dd342, at editor_assembly.rb:378. No new entry is needed.
- The periodic security Low (3) at tools/ci_scope.sh:66 (word-split) is already in the ci-hardening entry and needs no new entry.
- build/plan/backlog.md adds 17 entries for the b0dd342 periodic findings. Before adding the merge-tool hook Low (4) entry at .claude/agents/merger.md:15, check whether an existing merger.md entry already covers it and merge the two if so.
- The periodic security review at b0dd342 was partial (shell-tools not reviewed), so the next periodic review stays due.
- Package step: commit build/plan/queue.md as docs/queue.md (17,361 bytes against a 17,369 budget) and append build/plan/backlog.md to docs/backlog.md.
