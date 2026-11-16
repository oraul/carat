# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 9

1. `git-signs-status-a` (T2 user request, part a, estimated medium, split): no branch shows anywhere: `carat/plugins/` has no git plugin and `carat/plugin_api.rb` no request that runs a program (`set_status` at `:590`). Part a: the branch with ahead and behind counts in the status line; part b (pool) the line signs. Fix outline: a git plugin and the host request it needs (a `PluginApi::Host` method, a `PluginLink` override, a minor version bump), git run without a shell, its output untrusted text. Accepted when a test with a fake process shows the branch and both counts, outside a repository or without git nothing shows and no error escapes, the segment holds under `option.icons ascii`, and the docs rows land. Backlog: none.
2. `review-coverage` (T1 pipeline security, estimated medium): sprint 8 found the sprint security reviews skipped or missing a diff: Medium (5) `.claude/workflows/deliver-change.js:996` with `tools/run_state.sh:1712`: plan-needed reads notes only from pending runs, never the `review-*` or `sprint-*` run states a periodic security review records on, so a delivery of the queue head skips the security-first stop; Medium (4) `tools/run_state.sh:1507`: items marked `beyond the sprint` go uncounted without a cap, so review-due may never reach five; `tools/run_state.sh:1583`: sprint_row takes such rows after the fifth counted one, so a later diff reaches no sprint review; `:1492` a double negative. Fix outline: plan-needed sees a failing periodic security record no later merge fixed; uncounted exceptions bounded per sprint; the row ends at the fifth counted change. Accepted when a tools-test case fails before and passes after each, review-due fires after a fixed number of merges whatever the markers say, and tools-test seconds are not higher. Backlog: "### Sprint count exemption trusts model-written queue text", "### sprint_row takes exception rows past the fifth counted row", "### Double negative in the sprint exception count".
3. `lsp-incremental-sync` (T2 fix, estimated small): carat sends `textDocument/didChange` as one whole-document change with no range (`carat/adapters/json_rpc_language_gateway.rb:1311`) although ruby-lsp 0.26 declares incremental sync (`textDocumentSync` change 2); ruby-lsp applies each change by its range and drops a rangeless one, so after the first edit its copy is stale and completion answers InvalidLocationError. Fix outline: honor the server's sync kind, ranged changes (or one range covering the old text) for 2, whole text for 1. Accepted when a canned server announcing change 2 receives a range that reproduces the buffer, one announcing 1 receives whole text, and allocations hold. Backlog: none.
4. `spinel-notice` (T2 user request, docs, estimated medium, beyond the sprint, the user-approved exception): `tools/spinel/` carries a header generated from Spinel, but the credit at `README.md:212` names the MIT license without its copyright and permission notice (#137 advisory 2). Fix outline: a LICENSE file in `tools/spinel/` with Spinel's MIT copyright and permission notice, the copyright line without the email, the README credit pointing at it; no URL, no email. Accepted when that file holds the notice, the README credit names it, and docs-lint and gates pass. Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".

## Pool

1. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start, S10): Unstaged, Staged, Recent; `s`, `u`, `c` in a message buffer (`:wq` commits, empty aborts), `?` help, a confirmation before anything destructive.
2. `git-signs-status-b` (T2 user request, part b, estimated medium, S10): added, changed, deleted line signs.
3. `lint-panel` (T2 user request, estimated large, split at its start, S10): diagnostics list, Enter jumps; rubocop state in the status line; quickfix `:grep :make :cnext :copen`.
4. `git-push-pull` (T2 user request, estimated medium, S10): `P` asks before a push, never force; `F` pulls.
5. `git-diff-blame` (T2 user request, estimated medium, S10): `=` diffs the file; a blame line.
6. `ci-workflow-tidy` (T1 pipeline defect, estimated medium, split at its start, S10's pipeline): sprint-8 quality blocking: an equal-tree merge changing only the `Makefile`, `tools/metrics.sh`, `bench/`, or `config/` hits the .rb-keyed probe (`.github/workflows/main.yml:47`), skipping the release build, its smoke test (Low (5) `main.yml:155`), and main's measurement; #143 advisories 1, 2, 3, 7, 8 (`main.yml:52`, `:95`, `:151`). Accepted when a case fails before and passes after each.
7. `gateway-split-a` (T5 architecture-review M1, estimated medium, pushed back 1, S10): the gateway's 1,374 lines; `LspUri`, `Utf16Position`, `JsonRpcSession` first; folds `lsp-client-tidy`, `json_rpc_language_gateway.rb:469`, `:537`, `:931`, sweep `:774`, `:1089`, `:1` and `process_runner.rb:1` requires.
8. `backlog-read-guard` (T1 pipeline, estimated small, pushed back 1): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (3 of 4 searching starts at #129, #140 package once). Accepted when a case refuses each read form and an append passes.
9. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 3, reason: Medium (5) and (6), below 8, each needing a planted local object or record): a planted `.git/objects` object substitutes main's content in the merge gates (`.claude/agents/merger.md:12`); sweep Medium (6) `tools/gates.sh:415`, review records branch code can write.
10. `frame-painters` (T5 architecture-review M2, estimated medium, S10): the presenter's 1,274 lines.
11. `ux-fixes-a` (T2 user now-request, estimated medium, S10 by the user): ux-pass findings 3, 5, 10, the visible defects: the status-bar hole, the finder dropping its query, the palette's internal names.
12. `language-any` (T2 user request, estimated medium, S11): `language.<name>.lsp` lines.
13. `vim-macros-marks` (T2 user request, estimated medium, S11).
14. `vim-case-increment` (T2 user request, estimated medium, S11).
15. `own-line-advisories` (T1 pipeline, estimated medium, S11): advisories on a change's own lines reach the backlog (#143 8 of 8); #138 package 20 of 30 calls redoing an append. Accepted when every handed finding is in the merged backlog diff, checked by a case.
16. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11): with the sweep's `json_rpc_language_gateway.rb:691`, `:838`, `:222`, `:268`.
17. `vim-line-commands` (T2 user request, estimated medium, S12).
18. `vim-folds` (T2 user request, estimated medium, S12).
19. `markdown-reading-b` (T2 user now-request, part b, estimated medium, S12).
20. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes names no queue marker (#141, #145); sprint-8 `CLAUDE.md:213`.
21. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
22. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
23. `formatting` (T5 roadmap 14, estimated medium, S13).
24. `ux-pass-2` (T2 user now-request, estimated medium, S13).
25. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13 by the guide): merge at or over 12 calls in 10 of the last 12 runs (#145, #146 14 over 12, 4 waiting); 4 runs stored a wrong commit (#146). Accepted when 5 green merges stay at or under 9 calls, wait in at most 1, spend under 6,000, and 3 runs store main's squash commit, verified in git.
26. `language-followers` (T5 architecture-review H2, estimated medium, S13).
27. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S14).
28. `release-build` (T5 roadmap 15, estimated medium, S14).
29. `sample-plugin` (T5 user-scheduled, estimated medium, S14).
30. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 3, S14): a merged name replayed #95 (120K). Accepted when a case refuses or fresh-starts it.
31. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; `test/lint.rb:255`; `docs/spinel-notes.md:47`.
32. `dogfooding` (T2 user request, estimated medium, S15).
33. `ux-fixes-b` (T2 user now-request, estimated medium, split at its start, S15 by the user): ux-pass findings 1, 2, 4, 6, 7, 8, 9, 11.
34. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): reviews 21.9% to 26.5% of output at #141 to #145; #145 round 2 repeated 2 of 4. Accepted when 3 runs keep reviews under 18%, none repeated, quality first pass no lower.
35. `record-tier` (T1 pipeline retrospective, estimated small): record weighs 102,694 to 104,254 weighted a start against the checker's 1,113 to 3,506. Accepted when 3 runs stay under 5,000 a start and the gates still read the records.
36. `prose-grep-cases` (T1 pipeline retrospective, estimated medium): 17 of 957 expect lines grep agent prose (`tools/tools_test.sh:2790`, `:2795`, sprint-8 `:2833`); tools-test 92 of 217 check seconds. Accepted when no case greps prose a stub can prove and tools-test seconds are not higher.
37. `plan-apply-guard` (T1 pipeline retrospective, estimated small): #145's package applied the planner's queue over the branch's own queue edit, reverting a marker and carrying a stale path that failed docs-lint (1 extra commit). Accepted when a case keeps the branch edit or stops naming the conflict.
38. `sprint-marker-tidy` (T1 pipeline advisories, estimated small): sprint-8 `tools/run_state.sh:1494` one test three times, `:289` names, `tools/docs_lint.sh:154` counts marked items; `:1121`, `:1143` (#145).
39. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).
40. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
41. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
42. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
43. `finder-grep` (T5 user request, estimated medium, pushed back 6).
44. `definition-tab` (T5 user request, estimated medium, pushed back 6).
45. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
46. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
47. `filetype-rules` (T5 user request, estimated medium, pushed back 6).
48. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).
49. `syntax-forms` (T5 user request, estimated medium, pushed back 6).
50. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).
51. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).
52. `html-syntax` (T5 user request, estimated medium, pushed back 6).
53. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7) `sprint-planning.js:121`.
54. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7) `gates.sh:224`.
55. `ci-scope-quoting` (T1 pipeline, Low (6), estimated medium, pushed back 3): `tools/ci_scope.sh:95`, `:78`, `:31`, `tools/run_state.sh:503`; sweep `tools/rules.sh:73` (an architecture-only change skips tests), `ci_scope.sh:99`, `:80`; sprint-8 `rules.sh:70`, `run_state.sh:233`, `ci_scope.sh:42`. Accepted when a case fails before and passes after each.
56. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 3): quality 52/105 first pass. Accepted above 60% over 10 changes.
57. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
58. `run-resume` (T1 retrospective, estimated medium, pushed back 17): `deliver-change.js:967` builds the resume brief before the planner runs (#141).
59. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6) `run_state.sh:571`; `toolchain-clean` (sweep `Makefile:203`).
60. `spinel-bump` (T3 toolchain, estimated medium): upstream Spinel is about 90 commits past the pinned `SPINEL_REF` 93d7883b; bump in its own change after `make check`, regenerating the vendored header.
61. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
62. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): tag-pinned actions (sweep Low (5) `open-pr.yml:45`); sweep Low (7) `scan.yml:13`.
63. `project-config-guards` (T3, estimated medium, pushed back 23): a cloned `.caratrc` binds a write (`config.rb:221`).
64. `insert-copy` (T4, estimated small, pushed back 12).
65. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`, `:22`.
66. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.
67. `architecture-docs` (T6, estimated small, pushed back 1): floats (M4); sweep map drift `docs/codebase-map.md:99`, `:232`, `:530`; `carat/testing.rb:4`.
68. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
69. `ex-handlers-tidy` (T6 sweep, estimated medium): `history_command_handler.rb:44`.
70. `editing-counts` (T6, estimated medium, pushed back 11).
71. `hover-tidy` (T6, estimated medium, pushed back 13): sweep `show_hover.rb:74`.
72. `signature-tidy` (T6, estimated medium, pushed back 12).
73. `slots-tidy` (T6, estimated medium, pushed back 12).
74. `completion-tidy` (T6, estimated medium, pushed back 14).
75. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
76. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
77. `definitions-tidy` (T6, estimated medium, pushed back 11).
78. `plugin-host-tidy` (T6 sweep, estimated medium, pushed back 1): `plugin_router.rb:40`; sweep `plugin_host.rb:73` and 9 more.
79. `input-core-tidy` (T6 sweep, estimated medium, pushed back 1): `handle_key.rb:253`.
80. `core-correctness-b` (T6 sweep, estimated small): `carat/domain/buffer.rb:656`, `carat/domain/keymap.rb:348`, `carat/use_cases/handle_key.rb:198`; sweep `buffer.rb:406`, `command_grammar.rb:97`.
81. `editing-dedup-a` (T6 sweep, estimated medium): the tab width fallback in 10 places (`carat/use_cases/dispatcher.rb:112`), `operate.rb:204`, `operators.rb:271`, `put_over_selection.rb:126`.
82. `editing-dedup-b` (T6 sweep, estimated small): `walker.rb:63`, `runs.rb:18`, `handle_key.rb:384`, `input_controller.rb:128`, `show_completion.rb:96`, `range.rb:4`, `buffer.rb:472`.
83. `ui-code-tidy` (T6 sweep, estimated medium, pushed back 1): `carat/domain/themes.rb:470`, `test/domain_theme.rb:453`.
84. `tools-docs-tidy` (T6 sweep, estimated medium, pushed back 1): `Makefile:254`, `docs/architecture.md:351`; #136 to #143 advisories.
85. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Guide

The user's guide (2026-11-15), security first and review findings adjusting it:

- S9 to S15 three features and two fixes each as the pool's sprint tags place them; S9 took S8's two items left, so S9's other tags moved to S10; `gate-object-pin` first if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Dropped: carat drawing its own glyphs (`nerd` stays an option); parallel lanes.

## Decisions

- `ruby-structure-check` (T2 user request), this change, estimated medium, not split: one feature, five openers, under four fixes; features ux-pass 676,270 total in 31 min, markdown-reading-a 1,035,751 in 74, under 1.2M.
- Removed from Sprint 9, nothing else reordered; Sprint 9 keeps 3 features, 2 fixes: features `markdown-reading-a` (#146), `ruby-structure-check`, `git-signs-status-a` (T2); fixes `review-coverage` (T1, the one pipeline) and `lsp-incremental-sync` (T2); `spinel-notice` beyond the sprint, the approved exception.
- #146 (quality 0 first pass, 1 rework): blocking `toggle_reading.rb:68` fixed before merge 67562e69905c; 5 advisories (`toggle_reading.rb:39`, `:86`, `docs_handler.rb:20`, `codebase-map.md:633`, `test/use_cases_toggle_reading.rb:83`) appended by its package, T6, left to sprint 9's grooming.
- #146 merge overrun 14 over 12 and a stored 67562e699059 for 67562e69905c folded into `merge-gate-integrity` (T1, pool 25): 10 of the last 12 at or over 12.
- #146 close start returned a placeholder twice (notes 8, 9) to the backlog (T1, 1 run), not queued until it repeats.
- Security: none open at 8 or above, none disputed: sprint-8 Medium (5), (4); sweep Medium (6).
- Pace: quality 52/105 first pass, ci 101/107, 88 rework rounds over 105 changes.
