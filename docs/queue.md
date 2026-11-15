# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 8

The user-approved exception (Guide): 5 items left, 3 pipeline; the marker `brief-only-relay` made docs-lint honor, applied in the same commit as this queue.

1. `ci-time-tidy` (T1 pipeline defects, estimated large, pushed back 1, split at its start): docs-only #130 spent 390 of 486 CI stage seconds on compile, test, bench; ci-stages drops fractional steps; `Makefile:79` stale; locally the checker ran 664 s of stages on docs-only #137 (diagnose 207, test-build 162), none checking a changed file; #138 spent 91 of 663 local s (13.7%) on tools-test, touching no file it tests; #140 ran 642 local s, CI compile 84 s and release build 63 s. Fix outline (the user's): two CI workflows, no overlap: pull requests only (the full checks, the required check name `spin` kept), push to main only (measurement, compile-cache warming, release build and smoke; the full checks only when the squash tree differs from the passed head, no compile when equal and cached); docs-only skips compile, test, bench. Accepted when a docs-only pull request runs only its paths' stages, its local check runs only docs-lint and gates in under 60 s, a change touching no file tools-test covers skips it locally and in CI, an equal-tree main push compiles nothing, and protection still sees `spin`. Backlog: "## CI time doubled after the Spinel pin bump".
2. `scout-focus` (T1 pipeline retrospective, estimated medium, pushed back 5): scouts 51,496 of 127,096 output (40.5%) and 62 of 166 calls at #140 against implement 30,295, the packs counting 27 calls of their own; 18.7% at #135, 32.1% at #134, 20.9% at #137 (a root LICENSE in no map area), against 472 and 1,397 at #130, #133 (`.claude/workflows/deliver-change.js:994`, `.claude/agents/scout.md` step 8). Fix outline: a scout reads only what the change's locations need; no scout for a change in no map area. Accepted when three code changes spend under 15% of output, under the implement phase, and fewer calls than the contributor on scouts, recorded calls matching the packs' within 5, a change in no map area starts no scout or spends under 2%, first passes unchanged. Backlog: "## The scout's step 8 says every Rules line names sections".
3. `sprint-tidy` (T1 pipeline defects, estimated medium, pushed back 1, split at its start): a brief fixing the order still plans (#135 plan 14.9% of output), a resume whose brief holds the main session's decisions starts a full planner (#136 41,075 of 242,766, 16.9%, 20 calls); history skips a never-merged row (`tools/run_state.sh:1372`); review-due counts a user-approved exception toward a sprint's five. Fix outline: plan-needed sees a fixed order, history keeps unmerged rows out, review-due skips marked items. Accepted when each fails in a case before and passes after. Backlog: none.
4. `spinel-notice` (T2 user request, docs, estimated small, the user-approved exception): `tools/spinel/` carries a header generated from Spinel, but the credit at `README.md:212` names the MIT license without its copyright and permission notice (#137 advisory 2). Fix outline: a LICENSE file in `tools/spinel/` with Spinel's MIT copyright and permission notice, the copyright line without the email, and the README credit pointing at it; no URL, no email. Accepted when that file holds the notice, the README credit names it, and docs-lint and gates pass. Backlog: "### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)".
5. `markdown-reading-a` (T2 user now-request, part a, estimated medium, pushed back 5): no key shows a Markdown buffer as readable text (measure, headings, lists, quotes); `carat/domain/markdown_text.rb:27` draws box cells under `option.icons ascii`, against `README.md:171`; its module comment at line 10 omits the spans `parse` keeps. Fix outline: a bound toggle drawing the buffer as reading text within the icon set. Accepted when snapshots show the view and the toggle, no escape byte or ascii-set box cell is drawn, an over-cap document stays bounded, and `docs/actions.md` has the row. Backlog: "## The MarkdownText comment still says plain rows".

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
14. `own-line-advisories` (T1 pipeline, estimated medium, S11): advisories on a change's own lines reach the backlog (#134 6 of 6, #133 3 of 3, #139 5 of 5); #138 package 20 of 30 calls redoing an append; #140 lost 1 of 4 handed findings. Accepted when every handed finding appears in the merged backlog diff as a ### entry with Location, Why, Fix, checked by a case.
15. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11).
16. `vim-line-commands` (T2 user request, estimated medium, S12).
17. `vim-folds` (T2 user request, estimated medium, S12).
18. `markdown-reading-b` (T2 user now-request, part b, estimated medium, S12).
19. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes.
20. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
21. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
22. `formatting` (T5 roadmap 14, estimated medium, S13).
23. `ux-pass-2` (T2 user now-request, estimated medium, S13).
24. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13 by the guide): #140 merge 10,307 output, 14 calls over its cap of 12, 4 waiting on a 6.3 min CI; 4 of the last 10 merges over 12 calls; #136 stored d180d78de192 for d180d78de199. Accepted when 5 green merges stay within the cap, wait in at most 2 calls, spend under 6,000, and the merged commit is verified in git before it is stored.
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
35. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).
36. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
37. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
38. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
39. `finder-grep` (T5 user request, estimated medium, pushed back 6).
40. `definition-tab` (T5 user request, estimated medium, pushed back 6).
41. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
42. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
43. `filetype-rules` (T5 user request, estimated medium, pushed back 6).
44. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).
45. `syntax-forms` (T5 user request, estimated medium, pushed back 6).
46. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).
47. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).
48. `html-syntax` (T5 user request, estimated medium, pushed back 6).
49. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7) `sprint-planning.js:121`.
50. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7) `gates.sh:224`.
51. `ci-scope-quoting` (T1 pipeline, Low (6), estimated small, pushed back 3): `tools/ci_scope.sh:95`, `:78`.
52. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 3): quality 48/99 first pass. Accepted above 60% over 10 changes.
53. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
54. `run-resume` (T1 retrospective, estimated medium, pushed back 17).
55. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6) `run_state.sh:571`; `toolchain-clean`.
56. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
57. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): tag-pinned actions, `open-pr.yml:46`.
58. `project-config-guards` (T3, estimated medium, pushed back 23): a cloned `.caratrc` binds a write (`config.rb:221`).
59. `insert-copy` (T4, estimated small, pushed back 12).
60. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`.
61. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.
62. `architecture-docs` (T6, estimated small, pushed back 1): floats (M4); `wrap`, `clipboard`.
63. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
64. `ex-handlers-tidy` (T6 sweep, estimated medium): `history_command_handler.rb:44`.
65. `editing-counts` (T6, estimated medium, pushed back 11).
66. `hover-tidy` (T6, estimated medium, pushed back 13).
67. `signature-tidy` (T6, estimated medium, pushed back 12).
68. `slots-tidy` (T6, estimated medium, pushed back 12).
69. `completion-tidy` (T6, estimated medium, pushed back 14).
70. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
71. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
72. `definitions-tidy` (T6, estimated medium, pushed back 11).
73. `plugin-host-tidy` (T6 sweep, estimated medium, pushed back 1): `plugin_router.rb:40`.
74. `input-core-tidy` (T6 sweep, estimated medium, pushed back 1): `handle_key.rb:253`.
75. `core-correctness-b` (T6 sweep, estimated small): #140's own lines: a reverted edit brings deleted marked rows back unmarked for `:g` (`carat/domain/buffer.rb:656`), `carat/domain/keymap.rb:348` walks the trie twice, timeout follow-ups beyond hover untested (`carat/use_cases/handle_key.rb:198`).
76. `ui-code-tidy` (T6 sweep, estimated medium, pushed back 1): `carat/domain/themes.rb:470`, `test/domain_theme.rb:453`, `:376`, `:257`.
77. `tools-docs-tidy` (T6 sweep, estimated medium, pushed back 1): `docs/examples.md:25`, `:31`; `Makefile:303`; #136's advisories (`Makefile:317`, `:87`, `tools/spinel_warnings.sh:42`); warnings printed twice (`Makefile:254`); section 10 (`docs/architecture.md:351`); the two `make types` entries; #139's 5 advisories; a standalone `test/domain_global.rb` compile.
78. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Guide

The user's guide (2026-11-15), security first and review findings adjusting it:

- S8, the user-approved speed-up exception to the one-pipeline limit and the 3/2 mix: `brief-only-relay`, `ci-time-tidy`, `scout-focus`, `sprint-tidy`, `spinel-notice`, `markdown-reading-a`.
- S9 to S15 three features and two fixes each as the pool's sprint tags place them; `gate-object-pin` first in S10 if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Dropped: carat drawing its own glyphs (`nerd` stays an option); parallel lanes.

## Decisions

- `brief-only-relay` (T1 pipeline) delivered now as Sprint 8 item 1 wrote it, the user-approved exception, first; removed; Sprint 8 holds 5 items, 3 pipeline (T1), 2 T2; nothing reordered.
- Estimated medium, not split: 2 fixes (the brief relay, the docs-lint marker) with their cases; tooling rows mit-license 636,713 in 30 min, carat-palette-b 750,242, spinel-warnings 1,443,603 at rework 1, medium under 1.2M.
- The Sprint 8 marker line stays: docs-lint allows 1 pipeline item (`tools/docs_lint.sh:153`) and this sprint holds 3, so the line matches the form the change's docs-lint honors.
- Sprint 7 grooming kept (`build/plan/sprint` names sprint-7, `docs/sprints.tsv` ends at sprint-6): 14 listed, 1 fixed by d180d78, 0 of 8 duplicate candidates.
- Sprint-7 review: 8 quality findings, 0 security; finding 1, 2, and #140 advisories into `core-correctness-b` (T6, pool 75); 3 to 6 into `tools-docs-tidy` (T6, pool 77); 7 into `ui-code-tidy`.
- #140 retro: scouts 40.5% into `scout-focus`; 1 of 4 handed findings lost into `own-line-advisories`; merge 14 calls of 12 into `merge-gate-integrity`.
- ux-pass findings 1 to 11 (T2) into `ux-fixes-a` and `ux-fixes-b` at S15.
- Security: none open at 8 or above; #140 0/0/0 at 58530dff872c; pooled Mediums (7) `sprint-security`, `content-gate-gaps`, (6) `check-runner-safety`, (5) `gate-object-pin`.
- Pace: quality 48/99 first pass, ci 95/101, 86 rework rounds over 99 changes.
