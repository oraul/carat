# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 9

1. `lsp-incremental-sync` (T2 fix, estimated small): carat sends `textDocument/didChange` as one whole-document change with no range (`carat/adapters/json_rpc_language_gateway.rb:1311`) although ruby-lsp 0.26 declares incremental sync (`textDocumentSync` change 2); ruby-lsp applies each change by its range and drops a rangeless one, so after the first edit its copy is stale and completion answers InvalidLocationError. Fix outline: honor the server's sync kind, ranged changes (or one range covering the old text) for 2, whole text for 1. Accepted when a canned server announcing change 2 receives a range that reproduces the buffer, one announcing 1 receives whole text, and allocations hold. Backlog: none.
2. `spinel-notice` (T2 user request, docs, estimated medium, beyond the sprint, the user-approved exception): `tools/spinel/` carries a header generated from Spinel, but the credit at `README.md:212` names the MIT license without its copyright and permission notice (#137 advisory 2). Fix outline: a LICENSE file in `tools/spinel/` with Spinel's MIT copyright and permission notice, the copyright line without the email, the README credit pointing at it; no URL, no email. Accepted when that file holds the notice, the README credit names it, and docs-lint and gates pass. Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".

## Pool

1. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start, S10): Unstaged, Staged, Recent; `s`, `u`, `c` in a message buffer (`:wq` commits, empty aborts), `?` help, a confirmation before anything destructive.
2. `git-signs-status-b` (T2 user request, part b, estimated medium, S10): added, changed, deleted line signs.
3. `lint-panel` (T2 user request, estimated large, split at its start, S10): diagnostics list, Enter jumps; rubocop state in the status line; quickfix `:grep :make :cnext :copen`.
4. `git-push-pull` (T2 user request, estimated medium, S10): `P` asks before a push, never force; `F` pulls.
5. `git-diff-blame` (T2 user request, estimated medium, S10): `=` diffs the file; a blame line.
6. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start, S10's pipeline): sprint-8 quality blocking: an equal-tree merge changing only the `Makefile`, `tools/metrics.sh`, `bench/`, or `config/` hits the .rb-keyed probe (`.github/workflows/main.yml:47`), skipping the release build, its smoke test (Low (5) `main.yml:155`), and main's measurement; #143 advisories 1, 2, 3, 7, 8 (`main.yml:52`, `:95`, `:151`). Accepted when a case fails before and passes after each.
7. `ruby-structure-bound` (T2 fix, estimated small, S10): #147's check slowed a Ruby open (10,000 lines 1.6 to 10.2 ms, 100,000 lines 22 to 116 ms) and rescans the whole buffer on every normal-mode change (`carat/plugins/ruby/plugin.rb:111`). Fix outline: rescan from the first changed line with the tokenizer's carried line state; skip the check above a line cap. Accepted when the 100,000-line open returns within 10% of main before #147 (22 ms), an edit near the end rescans only from that line, and lh-ruby, open-ruby, insert-ruby allocations hold. Backlog: "whole-buffer rescan on every normal-mode change (plugin.rb:111)".
8. `gateway-split-a` (T5 architecture-review M1, estimated medium, pushed back 1, S10): the gateway's 1,374 lines; `LspUri`, `Utf16Position`, `JsonRpcSession` first; folds `lsp-client-tidy`, `json_rpc_language_gateway.rb:469`, `:537`, `:931`, sweep `:774`, `:1089`, `:1` and `process_runner.rb:1` requires.
9. `backlog-read-guard` (T1 pipeline, estimated small, pushed back 1): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (3 of 4 searching starts at #129, #140 package once). Accepted when a case refuses each read form and an append passes.
10. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3, reason: Medium (5) and (6), below 8, each needing a planted local object or record): a planted `.git/objects` object substitutes main's content in the merge gates (`.claude/agents/merger.md:12`); sweep Medium (6) `tools/gates.sh:415`, review records branch code can write.
11. `frame-painters` (T5 architecture-review M2, estimated medium, S10): the presenter's 1,274 lines.
12. `ux-fixes-a` (T2 user now-request, estimated medium, S10 by the user): ux-pass findings 3, 5, 10, the visible defects: the status-bar hole, the finder dropping its query, the palette's internal names.
13. `language-any` (T2 user request, estimated medium, S11): `language.<name>.lsp` lines.
14. `vim-macros-marks` (T2 user request, estimated medium, S11).
15. `vim-case-increment` (T2 user request, estimated medium, S11).
16. `own-line-advisories` (T1 pipeline, estimated medium, S11): advisories on a change's own lines reach the backlog (#143 8 of 8); #138 package 20 of 30 calls redoing an append. Accepted when every handed finding is in the merged backlog diff, checked by a case.
17. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11): with the sweep's `json_rpc_language_gateway.rb:691`, `:838`, `:222`, `:268`.
18. `vim-line-commands` (T2 user request, estimated medium, S12).
19. `vim-folds` (T2 user request, estimated medium, S12).
20. `markdown-reading-b` (T2 user now-request, part b, estimated medium, S12).
21. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes names no queue marker (#141, #145); sprint-8 `CLAUDE.md:213`.
22. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
23. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
24. `formatting` (T5 roadmap 14, estimated medium, S13).
25. `ux-pass-2` (T2 user now-request, estimated medium, S13).
26. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13 by the guide): merge at or over 12 calls in 10 of the last 12 runs (#145, #146 14, #147 12, 4 waiting); 4 runs stored a wrong commit (#146); #146's close start returned the report "placeholder" with 0 tool calls and recorded false, so its record line ran only by hand. Accepted when 5 green merges stay at or under 9 calls, wait in at most 1, spend under 6,000, 3 runs store main's squash commit, verified in git, and a close returning recorded false or making no tool call starts once more, otherwise stops naming it in the report. Backlog: "### The close start returned a placeholder with no tool calls".
27. `language-followers` (T5 architecture-review H2, estimated medium, S13).
28. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S14).
29. `release-build` (T5 roadmap 15, estimated medium, S14).
30. `sample-plugin` (T5 user-scheduled, estimated medium, S14).
31. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 3, S14): a merged name replayed #95 (120K). Accepted when a case refuses or fresh-starts it.
32. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; `test/lint.rb:255`; `docs/spinel-notes.md:47`.
33. `dogfooding` (T2 user request, estimated medium, S15).
34. `ux-fixes-b` (T2 user now-request, estimated medium, split at its start, S15 by the user): ux-pass findings 1, 2, 4, 6, 7, 8, 9, 11.
35. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 32.9% of output at #141 to #147 (#147 27 of 129 calls, 0 blocking); #145 round 2 repeated 2 of 4. Accepted when 3 runs keep reviews under 18%, none repeated, quality first pass no lower.
36. `record-tier` (T1 pipeline retrospective, estimated small): record weighs 102,694 to 104,254 weighted a start against the checker's 1,113 to 3,506. Accepted when 3 runs stay under 5,000 a start and the gates still read the records.
37. `prose-grep-cases` (T1 pipeline retrospective, estimated medium): 17 of 957 expect lines grep agent prose (`tools/tools_test.sh:2790`, `:2795`, sprint-8 `:2833`); tools-test 92 of 217 check seconds. Accepted when no case greps prose a stub can prove and tools-test seconds are not higher.
38. `plan-apply-guard` (T1 pipeline retrospective, estimated small): #145's package applied the planner's queue over the branch's own queue edit, reverting a marker and carrying a stale path that failed docs-lint (1 extra commit). Accepted when a case keeps the branch edit or stops naming the conflict.
39. `sprint-marker-tidy` (T1 pipeline advisories, estimated small): sprint-8 `tools/run_state.sh:1494` one test three times, `:289` names, `tools/docs_lint.sh:154` counts marked items; `:1121`, `:1143` (#145); #149 `run_state.sh:1599` sprint cut by row order, not merge order, `:1730` last row only, `:1753` ls pipe and no blocking=0 case, `:1726` comment wrap.
40. `plan-skip` (T1 pipeline retrospective, estimated small): the plan phase ran in 10 of the last 10 rows, 159,199 of 1,159,581 output (13.7%); #147's 13,718/10 made 6 decisions, none changing the queue. Accepted when plan-needed finds no decision for a queue head delivered as queued with no new finding, and the plan phase is absent in 2 of the next 5 runs with no overrun or reorder missed.
41. `scout-value` (T1 pipeline retrospective, estimated small): #148 scout 31,419/27 (16.6% of 189,491 output) and implement still 95 calls, the most in 11 rows; runs with scout at 3 calls or fewer averaged 55.5 implement calls, at 25 or more 64.5. Accepted when over the next 5 runs scout plus implement calls stay at or below the last-10 median of 60 and implement calls do not rise.
42. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).
43. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
44. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
45. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
46. `finder-grep` (T5 user request, estimated medium, pushed back 6).
47. `definition-tab` (T5 user request, estimated medium, pushed back 6).
48. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
49. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
50. `filetype-rules` (T5 user request, estimated medium, pushed back 6).
51. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).
52. `syntax-forms` (T5 user request, estimated medium, pushed back 6).
53. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).
54. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).
55. `html-syntax` (T5 user request, estimated medium, pushed back 6).
56. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7) `sprint-planning.js:121`.
57. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7) `gates.sh:224`.
58. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3): `tools/ci_scope.sh:95`, `:78`, `:31`, `tools/run_state.sh:503`; sweep `tools/rules.sh:73` (an architecture-only change skips tests), `ci_scope.sh:99`, `:80`; sprint-8 `rules.sh:70`, `run_state.sh:233`, `ci_scope.sh:42`. Accepted when a case fails before and passes after each.
59. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 3): quality 53/107 first pass, 0 in 4 of the last 6 rows (#144, #145, #146, #148); #148 note 18: both blockers were spec clauses with no scenario while gates passed. Accepted above 60% over 10 changes, and quality blocked for an untested behavior in at most 1 of the next 5 runs.
60. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
61. `run-resume` (T1 retrospective, estimated medium, pushed back 17): `deliver-change.js:967` builds the resume brief before the planner runs (#141).
62. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6) `run_state.sh:571`; `toolchain-clean` (sweep `Makefile:203`).
63. `spinel-bump` (T3 toolchain, estimated medium): upstream Spinel is about 90 commits past the pinned `SPINEL_REF` 93d7883b; bump in its own change after `make check`, regenerating the vendored header.
64. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
65. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): tag-pinned actions (sweep Low (5) `open-pr.yml:45`); sweep Low (7) `scan.yml:13`.
66. `project-config-guards` (T3, estimated medium, pushed back 23): a cloned `.caratrc` binds a write (`config.rb:221`).
67. `insert-copy` (T4, estimated small, pushed back 12).
68. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`, `:22`.
69. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.
70. `architecture-docs` (T6, estimated small, pushed back 1): floats (M4); sweep map drift `docs/codebase-map.md:99`, `:232`, `:530`; `carat/testing.rb:4`.
71. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
72. `ex-handlers-tidy` (T6 sweep, estimated medium): `history_command_handler.rb:44`.
73. `editing-counts` (T6, estimated medium, pushed back 11).
74. `hover-tidy` (T6, estimated medium, pushed back 13): sweep `show_hover.rb:74`.
75. `signature-tidy` (T6, estimated medium, pushed back 12).
76. `slots-tidy` (T6, estimated medium, pushed back 12).
77. `completion-tidy` (T6, estimated medium, pushed back 14).
78. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
79. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
80. `definitions-tidy` (T6, estimated medium, pushed back 11).
81. `plugin-host-tidy` (T6 sweep, estimated medium, pushed back 1): `plugin_router.rb:40`; sweep `plugin_host.rb:73` and 9 more.
82. `input-core-tidy` (T6 sweep, estimated medium, pushed back 1): `handle_key.rb:253`.
83. `core-correctness-b` (T6 sweep, estimated small): `carat/domain/buffer.rb:656`, `carat/domain/keymap.rb:348`, `carat/use_cases/handle_key.rb:198`; sweep `buffer.rb:406`, `command_grammar.rb:97`.
84. `editing-dedup-a` (T6 sweep, estimated medium): the tab width fallback in 10 places (`carat/use_cases/dispatcher.rb:112`), `operate.rb:204`, `operators.rb:271`, `put_over_selection.rb:126`.
85. `editing-dedup-b` (T6 sweep, estimated small): `walker.rb:63`, `runs.rb:18`, `handle_key.rb:384`, `input_controller.rb:128`, `show_completion.rb:96`, `range.rb:4`, `buffer.rb:472`.
86. `ui-code-tidy` (T6 sweep, estimated medium, pushed back 1): `carat/domain/themes.rb:470`, `test/domain_theme.rb:453`.
87. `tools-docs-tidy` (T6 sweep, estimated medium, pushed back 1): `Makefile:254`, `docs/architecture.md:351`; #136 to #143 advisories.
88. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Guide

The user's guide (2026-11-15), security first and review findings adjusting it:

- S9 to S15 three features and two fixes each as the pool's sprint tags place them; S9 took S8's two items left, so S9's other tags moved to S10; `gate-object-pin` first if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Dropped: carat drawing its own glyphs (`nerd` stays an option); parallel lanes.

## Decisions

- `review-coverage-b` (T1 pipeline security), this change, estimated medium, not split: 1 fix (`tools/run_state.sh:1731`) and 1 tools-test case; no row of the last 10 under 676,270 total (`brief-only-relay`, 1 pipeline fix, 677,866 in 33 min), over small's 500k.
- Delivered ahead of head `lsp-incremental-sync` (plan-needed: not the head): it finishes `review-coverage` (#149: CI green, security pass 0 findings, quality blocked by note 8 `run_state.sh:1731`, its 1 push spent), Sprint 9's one pipeline fix; nothing reordered.
- Sprint 9 keeps 3 features (#146, #147, #148), 2 fixes (`review-coverage-b` T1, the one pipeline; `lsp-incremental-sync` T2); `spinel-notice` the approved exception.
- #149 note 5 (a run resumed past its plan clears the review unseen) is note 8's defect, covered by this change's acceptance; not queued apart.
- #149 advisories 9 to 13 (late 14 to 18) re-raise its round-1 notes 2, 3, 4, 6, 7, appended by its package (722bb14, backlog +42 lines): folded into `sprint-marker-tidy` (T1, pool 39) by location, no new backlog entry; #149 never merges, so `history` adds no row or late findings for it.
- Security: none open at 8 or above, none disputed: #149 high 0 medium 0; sprint-8 Medium (5), (4) fixed by #149's commits carried here; sprint-8-sweep Medium 1 below 8 in `gate-object-pin`.
- Pace: quality 53/108 first pass, ci 104/110, 90 rework rounds over 108 changes; #149 quality first pass 0, rework 1.
