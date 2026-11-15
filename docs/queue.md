# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 8

The user-approved exception (Guide): 5 items left, 3 pipeline; the marker `brief-only-relay` made docs-lint honor, applied in the same commit as this queue.

1. `ci-time-tidy-b` (T1 pipeline defects, part b, estimated medium, pushed back 1): part a (`ci-time-tidy`) scoped the stages to the changed paths; left: every pull request runs the release build (63 s) and its smoke (23 s) beside compile 84 s (#140, `.github/workflows/ci.yml`), and `tools/run_state.sh` ci-stages drops fractional steps. Fix outline (the user's): two CI workflows, no overlap: pull requests only (the full checks, the required check name `spin` kept), push to main only (measurement, compile-cache warming, release build and smoke; the full checks only when the squash tree differs from the passed head, no compile when equal and cached); ci-stages keeps a fractional step. Accepted when an equal-tree main push compiles nothing, a differing-tree push runs the full checks, a pull request runs no main-only step, protection still sees `spin`, and a case records a fractional step. Backlog: "## CI time doubled after the Spinel pin bump".
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
19. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes; `.claude/agents/planner.md:35` never names the exception marker line it writes (#141 advisory 4).
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
52. `ci-scope-quoting` (T1 pipeline, Low (6), estimated small, pushed back 3): `tools/ci_scope.sh:95`, `:78`.
53. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 3): quality 49/100 first pass. Accepted above 60% over 10 changes.
54. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
55. `run-resume` (T1 retrospective, estimated medium, pushed back 17): #141 `.claude/workflows/deliver-change.js:967` builds the resume brief before the planner runs, so it misses `build/plan/queue.md`.
56. `check-runner-safety` (T1 security, estimated medium, pushed back 15): Medium (6) `run_state.sh:571`; `toolchain-clean`.
57. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
58. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): tag-pinned actions, `open-pr.yml:46`.
59. `project-config-guards` (T3, estimated medium, pushed back 23): a cloned `.caratrc` binds a write (`config.rb:221`).
60. `insert-copy` (T4, estimated small, pushed back 12).
61. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`.
62. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.
63. `architecture-docs` (T6, estimated small, pushed back 1): floats (M4); `wrap`, `clipboard`.
64. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
65. `ex-handlers-tidy` (T6 sweep, estimated medium): `history_command_handler.rb:44`.
66. `editing-counts` (T6, estimated medium, pushed back 11).
67. `hover-tidy` (T6, estimated medium, pushed back 13).
68. `signature-tidy` (T6, estimated medium, pushed back 12).
69. `slots-tidy` (T6, estimated medium, pushed back 12).
70. `completion-tidy` (T6, estimated medium, pushed back 14).
71. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
72. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
73. `definitions-tidy` (T6, estimated medium, pushed back 11).
74. `plugin-host-tidy` (T6 sweep, estimated medium, pushed back 1): `plugin_router.rb:40`.
75. `input-core-tidy` (T6 sweep, estimated medium, pushed back 1): `handle_key.rb:253`.
76. `core-correctness-b` (T6 sweep, estimated small): #140's own lines: a reverted edit brings deleted marked rows back unmarked for `:g` (`carat/domain/buffer.rb:656`), `carat/domain/keymap.rb:348` walks the trie twice, timeout follow-ups beyond hover untested (`carat/use_cases/handle_key.rb:198`).
77. `ui-code-tidy` (T6 sweep, estimated medium, pushed back 1): `carat/domain/themes.rb:470`, `test/domain_theme.rb:453`, `:376`, `:257`.
78. `tools-docs-tidy` (T6 sweep, estimated medium, pushed back 1): `docs/examples.md:25`, `:31`; `Makefile:303`; #136's advisories (`Makefile:317`, `:87`, `tools/spinel_warnings.sh:42`); warnings printed twice (`Makefile:254`); section 10 (`docs/architecture.md:351`); the two `make types` entries; #139's 5 advisories; a standalone `test/domain_global.rb` compile; #141's advisories (`tools/tools_test.sh:1829`, `:2718`, `tools/docs_lint.sh:157`, `CLAUDE.md:204`).
79. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Guide

The user's guide (2026-11-15), security first and review findings adjusting it:

- S8, the user-approved speed-up exception to the one-pipeline limit and the 3/2 mix: `brief-only-relay`, `ci-time-tidy`, `scout-focus`, `sprint-tidy`, `spinel-notice`, `markdown-reading-a`.
- S9 to S15 three features and two fixes each as the pool's sprint tags place them; `gate-object-pin` first in S10 if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Dropped: carat drawing its own glyphs (`nerd` stays an option); parallel lanes.

## Decisions

- `ci-time-tidy` (T1 pipeline defects) estimated large: 7 separate fixes in the brief, over the about-four limit; the tooling row spinel-warnings took 1,443,603 total in 100 min. Split: part a delivered now, part b `ci-time-tidy-b` stays Sprint 8 item 1.
- Part a, this change, estimated medium: stages scoped to the changed paths: a docs-only pull request skips compile, test, bench (#130 390 of 486 CI s), its local check runs docs-lint and gates under 60 s (#137 664 s), tools-test skipped when no covered file changed (#138 91 of 663 s), `Makefile:79`; rows core-correctness 853,938, carat-palette-b 750,242.
- Part b (T1, estimated medium): the two workflows, the equal-tree main push, ci-stages fractional steps (#140 release build 63 s, smoke 23 s, compile 84 s); the heading "## CI time doubled after the Spinel pin bump" goes with part b, so its entry leaves when the whole lands; part a lists none.
- Nothing else reordered (brief); Sprint 8 keeps 5 items, 3 pipeline (T1), 2 T2, under the marker line.
- review-due counts every merge (`tools/run_state.sh:1438`): with the split, Sprint 8 reaches 5 merges at `sprint-tidy`, leaving `spinel-notice` and `markdown-reading-a` to the sprint-9 plan.
- #141 advisories (T6 and T1): 1 into `run-resume`; 2, 3, 5, 6 into `tools-docs-tidy`; 4 into `hook-one-place` (planner.md 8,190 of 8,192 bytes).
- #141 retro (T1): record 102,694 of 1,619,931 weighted (6.3%) into new `record-tier`, pool 35, untagged: S9 to S15 each hold their one pipeline item.
- Security: none open at 8 or above; #141 0/0/0 at 5629b9f031be; pooled Mediums (7) `sprint-security`, `content-gate-gaps`, (6) `check-runner-safety`, (5) `gate-object-pin`.
- Pace: quality 49/100 first pass, ci 96/102, 86 rework rounds over 100 changes.
