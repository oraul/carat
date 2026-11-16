# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 8

The user-approved exception (Guide): 3 items left, 1 pipeline; the marker `brief-only-relay` made docs-lint honor.

1. `sprint-tidy` (T1 pipeline defects, estimated medium, pushed back 1, split at its start): a brief fixing the order still plans (#135 plan 14.9% of output), a resume whose brief holds the main session's decisions starts a full planner (#136 41,075 of 242,766, 16.9%, 20 calls); history skips a never-merged row (`tools/run_state.sh:1372`); review-due counts a user-approved exception toward a sprint's five. Fix outline: plan-needed sees a fixed order, history keeps unmerged rows out, review-due skips marked items. Accepted when each fails in a case before and passes after. Backlog: none.
2. `spinel-notice` (T2 user request, docs, estimated small, user-approved beyond the sprint): `tools/spinel/` carries a header generated from Spinel, but the credit at `README.md:212` names the MIT license without its copyright and permission notice (#137 advisory 2). Fix outline: a LICENSE file in `tools/spinel/` with Spinel's MIT copyright and permission notice, the copyright line without the email, and the README credit pointing at it; no URL, no email. Accepted when that file holds the notice, the README credit names it, and docs-lint and gates pass. Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
3. `markdown-reading-a` (T2 user now-request, part a, estimated medium, pushed back 5): no key shows a Markdown buffer as readable text (measure, headings, lists, quotes); `carat/domain/markdown_text.rb:27` draws box cells under `option.icons ascii`, against `README.md:171`; its module comment at line 10 omits the spans `parse` keeps. Fix outline: a bound toggle drawing the buffer as reading text within the icon set. Accepted when snapshots show the view and the toggle, no escape byte or ascii-set box cell is drawn, an over-cap document stays bounded, and `docs/actions.md` has the row. Backlog: "## The MarkdownText comment still says plain rows".

## Pool

1. `ruby-structure-check` (T2 user request, estimated medium, S9): the Ruby tokenizer flags an unclosed `def`, `class`, `module`, `do`, `if` at once, no language server; a table test per opener, keys held.
2. `git-signs-status` (T2 user request, estimated medium, S9): added, changed, deleted line signs; branch with ahead and behind in the status line.
3. `git-panel` plugin (T2 user request, estimated large, split at its start, S9): Unstaged, Staged, Recent; `s`, `u`, `c` in a message buffer (`:wq` commits, empty aborts), `?` help, a confirmation before anything destructive.
4. `backlog-read-guard` (T1 pipeline, estimated small, S9): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (3 of 4 searching starts at #129, the #140 package start once). Accepted when a case refuses each read form and an append passes.
5. `gateway-split-a` (T5 architecture-review M1, estimated medium, S9): the gateway's 1,374 lines; `LspUri`, `Utf16Position`, `JsonRpcSession` first; folds `lsp-client-tidy`, `json_rpc_language_gateway.rb:469`, `:537`, `:931`.
6. `lint-panel` (T2 user request, estimated large, split at its start, S10): diagnostics list, Enter jumps; rubocop state in the status line; quickfix `:grep :make :cnext :copen`.
7. `git-push-pull` (T2 user request, estimated medium, S10): `P` asks before a push, never force; `F` pulls.
8. `git-diff-blame` (T2 user request, estimated medium, S10): `=` diffs the file; a blame line.
9. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 2, S10): a planted `.git/objects` object substitutes main's content in the merge gates; scp origins accepted (Medium (5), `.claude/agents/merger.md:12`).
10. `frame-painters` (T5 architecture-review M2, estimated medium, S10): the presenter's 1,274 lines.
11. `language-any` (T2 user request, estimated medium, S11): `language.<name>.lsp` lines.
12. `vim-macros-marks` (T2 user request, estimated medium, S11).
13. `vim-case-increment` (T2 user request, estimated medium, S11).
14. `own-line-advisories` (T1 pipeline, estimated medium, S11): advisories on a change's own lines reach the backlog (#134 6 of 6, #133 3 of 3, #139 5 of 5, #143 8 of 8, 4 one-line nits on its own lines; reviews 24.4% of #143 output); #138 package 20 of 30 calls redoing an append; #140 lost 1 of 4 handed findings. Accepted when every handed finding appears in the merged backlog diff as a ### entry with Location, Why, Fix, checked by a case.
15. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11).
16. `vim-line-commands` (T2 user request, estimated medium, S12).
17. `vim-folds` (T2 user request, estimated medium, S12).
18. `markdown-reading-b` (T2 user now-request, part b, estimated medium, S12).
19. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes; `.claude/agents/planner.md:35` never names the exception marker line it writes (#141 advisory 4).
20. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
21. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
22. `formatting` (T5 roadmap 14, estimated medium, S13).
23. `ux-pass-2` (T2 user now-request, estimated medium, S13).
24. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13 by the guide): #140 merge 10,307 output, 14 calls over its cap of 12, 4 waiting on a 6.3 min CI; #142 13 calls, 6 waiting on an 8.2 min CI; #143 12 calls, 4 waiting on a 7.0 min CI; 4 of the last 10 merges over 12 calls; #136 stored d180d78de192 for d180d78de199; #142 stored the head 97e55861412b for main's ca36ad587cf9, #143 f39c2857fba2 for 7b03a5e0080c (retros). Accepted when 5 green merges stay within the cap, wait in at most 2 calls, spend under 6,000, and over 3 runs the notes, record line, and run state hold main's squash commit, verified in git before it is stored.
25. `language-followers` (T5 architecture-review H2, estimated medium, S13).
26. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S14).
27. `release-build` (T5 roadmap 15, estimated medium, S14).
28. `sample-plugin` (T5 user-scheduled, estimated medium, S14).
29. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 3, S14): a merged name replayed #95 (120K). Accepted when a case refuses or fresh-starts a merged name.
30. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; #134's typed test reads; #135's advisories; `test/lint.rb:255` arrays; the 6 open `docs/spinel-notes.md:47` entries.
31. `dogfooding` (T2 user request, estimated medium, S15).
32. `ux-fixes-a` (T2 user now-request, estimated medium, S15 by the guide): ux-pass findings 1, 2, 3, 6, 7, 8: hints after the logo, the Ctrl-C hint, the lsp segment's background, insert shown twice, the key-hint names, the completion border.
33. `ux-fixes-b` (T2 user now-request, estimated medium, S15 by the guide): ux-pass findings 4, 5, 9, 10, 11: explorer help, finder Enter on no match, palette and finder frames, palette rows, a leader buffer picker.
34. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15): docs-only skip_specs quality reviews 60,089 of 343,322 output (17.5%), 4 of 4 first pass. Accepted when 3 such changes spend under half, the security review still runs.
35. `record-tier` (T1 pipeline retrospective, estimated small): the record start, one queued command, weighs 102,694 to 104,135 weighted tokens in all 10 last rows (#140 6.3% of 1,619,931) at session/low, against the checker's 1,682 to 3,506 at cheap/low (#141 retro). Accepted when over 3 runs record stays under 5,000 weighted per start, every record line exits 0, and the gates still read the records.
36. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).
37. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
38. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
39. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
40. `finder-grep` (T5 user request, estimated medium, pushed back 6).
41. `definition-tab` (T5 user request, estimated medium, pushed back 6).
42. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
43. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
44. `filetype-rules` (T5 user request, estimated medium, pushed back 6).
45. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).
46. `syntax-forms` (T5 user request, estimated medium, pushed back 6).
47. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).
48. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).
49. `html-syntax` (T5 user request, estimated medium, pushed back 6).
50. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7) `sprint-planning.js:121`.
51. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7) `gates.sh:224`.
52. `ci-scope-quoting` (T1 pipeline, Low (6), estimated small, pushed back 3): `tools/ci_scope.sh:95`, `:78`; #142 advisories: the tests-only carry runs before the path scope, so a scoped dev-build is carried and test-run's smoke fails falsely (`tools/run_state.sh:503`); `tools/ci_scope.sh:31` overlong, names two output lines of three, and leaves an orphan line (#143 advisory 6). Accepted when a case fails before and passes after each.
53. `ci-workflow-tidy` (T1 pipeline advisories, estimated small): #143 advisories 1, 2, 3, 7, 8: the secs filter of `tools/run_state.sh:1250` no test runs; the compile cache key written three times (`.github/workflows/main.yml:52`, `.github/workflows/ci.yml`) and the check steps copied (`main.yml:95`), so a drift goes unseen; the probe keys on Ruby sources only, so a `Makefile` or `tools/metrics.sh` change keeps a stale measurement (`main.yml:47`); a redundant ref test (`main.yml:151`). Accepted when a case fails before and passes after each, the key and the steps checked equal in both workflows.
54. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 3): quality 49/100 first pass. Accepted above 60% over 10 changes.
55. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
56. `run-resume` (T1 retrospective, estimated medium, pushed back 17): #141 `.claude/workflows/deliver-change.js:967` builds the resume brief before the planner runs, so it misses `build/plan/queue.md`.
57. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6) `run_state.sh:571`; `toolchain-clean`.
58. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
59. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): tag-pinned actions, `open-pr.yml:46`.
60. `project-config-guards` (T3, estimated medium, pushed back 23): a cloned `.caratrc` binds a write (`config.rb:221`).
61. `insert-copy` (T4, estimated small, pushed back 12).
62. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`.
63. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.
64. `architecture-docs` (T6, estimated small, pushed back 1): floats (M4); `wrap`, `clipboard`.
65. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
66. `ex-handlers-tidy` (T6 sweep, estimated medium): `history_command_handler.rb:44`.
67. `editing-counts` (T6, estimated medium, pushed back 11).
68. `hover-tidy` (T6, estimated medium, pushed back 13).
69. `signature-tidy` (T6, estimated medium, pushed back 12).
70. `slots-tidy` (T6, estimated medium, pushed back 12).
71. `completion-tidy` (T6, estimated medium, pushed back 14).
72. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
73. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
74. `definitions-tidy` (T6, estimated medium, pushed back 11).
75. `plugin-host-tidy` (T6 sweep, estimated medium, pushed back 1): `plugin_router.rb:40`.
76. `input-core-tidy` (T6 sweep, estimated medium, pushed back 1): `handle_key.rb:253`.
77. `core-correctness-b` (T6 sweep, estimated small): #140's own lines: a reverted edit brings deleted marked rows back unmarked for `:g` (`carat/domain/buffer.rb:656`), `carat/domain/keymap.rb:348` walks the trie twice, timeout follow-ups beyond hover untested (`carat/use_cases/handle_key.rb:198`).
78. `ui-code-tidy` (T6 sweep, estimated medium, pushed back 1): `carat/domain/themes.rb:470`, `test/domain_theme.rb:453`, `:376`, `:257`.
79. `tools-docs-tidy` (T6 sweep, estimated medium, pushed back 1): `docs/examples.md:25`, `:31`; `Makefile:303`; #136's advisories (`Makefile:317`, `:87`, `tools/spinel_warnings.sh:42`); warnings printed twice (`Makefile:254`); section 10 (`docs/architecture.md:351`); the two `make types` entries; #139's 5 advisories; a standalone `test/domain_global.rb` compile; #141's advisories (`tools/tools_test.sh:1829`, `:2718`, `tools/docs_lint.sh:157`, `CLAUDE.md:204`); #142's (`tools/run_state.sh:461`, `tools/tools_test.sh:1862`); #143's (`README.md:189` and `CLAUDE.md` on the release build only on main, `Makefile:122`).
80. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Guide

The user's guide (2026-11-15), security first and review findings adjusting it:

- S8, the user-approved speed-up exception to the one-pipeline limit and the 3/2 mix: `brief-only-relay`, `ci-time-tidy`, `scout-focus`, `sprint-tidy`, `spinel-notice`, `markdown-reading-a`.
- S9 to S15 three features and two fixes each as the pool's sprint tags place them; `gate-object-pin` first in S10 if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Dropped: carat drawing its own glyphs (`nerd` stays an option); parallel lanes.

## Decisions

- `scout-focus` (T1 pipeline retrospective), this change, estimated medium: 2 fixes plus the recorded-calls match, under the about-four limit; pipeline rows ci-time-tidy 791,970 total in 49 min, ci-time-tidy-b 784,166 in 40 min, brief-only-relay 677,866 in 33 min, under the 1.2M medium budget. It covers "## The scout's step 8 says every Rules line names sections".
- Removed from Sprint 8, nothing reordered (brief); Sprint 8 holds 3 items, 1 pipeline (T1), 2 T2, under the marker line.
- review-due: this change is Sprint 8's fourth merge after #141, #142, #143; 5 reached at `sprint-tidy`, leaving `spinel-notice` and `markdown-reading-a` to the sprint-9 plan.
- #143 retro scout-focus (T1): scout 21,704 of 116,974 output (18.6%), 19 of 117 calls, 6 pack gaps unused: evidence for this change; its 5% target dropped, the brief fixing the acceptance at 15%.
- #143 retro own-line-advisories (T1): 8 of 8 advisories appended, 4 on its own lines; reviews 24.4% of output: into pool 14, not moved.
- #143 retro merge-gate-integrity (T1): f39c2857fba2 stored for main's 7b03a5e0080c; merge 12 calls at its cap of 12, 4 waiting on a 7.0 min CI: into pool 24, not moved (brief).
- #143 quality advisories (T1 and T6, all 8 appended by its package step): 1, 2, 3, 7, 8 into the new `ci-workflow-tidy`, pool 53, one CI domain; 6 into `ci-scope-quoting`, pool 52; 4 and 5 into `tools-docs-tidy`, pool 79.
- Security: none open at 8 or above; #143 0/0/0 at 56c291695205; pooled Mediums (7) `sprint-security`, `content-gate-gaps`, (6) `check-runner-safety`, (5) `gate-object-pin`.
- Pace: quality 51/102 first pass, ci 98/104, 86 rework rounds over 102 changes; #143 784,166 total in 40 min, within medium.
