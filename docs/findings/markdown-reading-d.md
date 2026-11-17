### MarkdownText.parse runs the marker scan twice per line
- Location: carat/domain/markdown_text.rb:114 (parse calling flow_key, then marker_end at line 123 or block at line 133)
- Why: each line's quote markers are scanned once in flow_key and again in marker_end or block, a repeated byte walk per row on reading views of up to 262,144 bytes, though the shared scanner was meant to read a line once.
- Fix: compute markers(line) once in parse and pass the packed scan to flow_key and block, marker_end becoming marker_stop(scan).
### The merger returns pending before its 30-minute CI wait ends (lsp-container-c retro)
- Location: `.claude/agents/merger.md` step 2; `.claude/workflows/deliver-change.js` merge phase
- Why: lsp-container-c's merger returned pending after 3 and then 0 of 30 minutes while CI was in progress, so the workflow started it three times on a CI that passed first time: merge took 30 of 119 calls (25.2%) and 12,961 output tokens, against a median of 12 merge calls over the last 10 feature rows. For `merge-gate-integrity`.
- Fix: the merger waits the full 30 minutes on a queued or running check before returning pending; accepted when over the next 5 runs no note reports an early pending return and merge stays at or under 15 calls on a first-pass green CI.

### Quality advisories still dropped at the package step (lsp-container-c retro)
- Location: `.claude/agents/contributor.md` package step 2
- Why: 3 of 3 lsp-container-c advisories (`carat/domain/config.rb:219`, `carat/domain/trusted_roots.rb:48`, `docs/codebase-map.md:100`) went only into the pull request Notes, now 14 of 23 dropped over the last 4 rows with advisories; quality first pass 71/136. For `review-demotion`.
- Fix: remove the contributor's judgment of which advisories to keep; accepted when over the next 5 runs every advisory is fixed or in the change's findings file, 0 dropped.

### Scout and areas starts repeat what the planner and contributor establish (lsp-container-c retro)
- Location: `.claude/workflows/deliver-change.js` areas and scout phases
- Why: lsp-container-c's scout and areas cost 41,568 of 220,432 output (18.9%) and 24 of 119 calls (20.2%) for an implement of 27 calls, the planner having named the check site and the contributor re-verifying both scout findings; lsp-container 25.9%, lsp-container-b 15.3% of output. For `scout-value`.
- Fix: skip or shrink the scouts when the brief names its locations; accepted when over the next 5 runs scout and areas stay under 10% of output, implement calls at or under the last-10 feature median (38), first passes not lower.
