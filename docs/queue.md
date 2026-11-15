# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 7

1. `core-correctness` (T6 periodic quality blocking, fix, estimated medium): four editing bugs the sprint-6 sweep raised again (blocking=2 at 4958dc6bd923): Tab under `expandtab` pads from the code-point column, so after a tab or a wide character it stops off the stop (`carat/use_cases/insert_tab.rb:23`; ts=4 after a tab and x lands on display column 7, not 8; the one test, `test/editor_insert.rb:64`, types after ASCII); a `none` unbinding walks with `child_for` and leaves empty trie nodes, so `keymap.normal xy none` makes `x` wait timeoutlen or with no deadline (`carat/domain/keymap.rb:228`); `Buffer#revert_to` skips the `global_marks.shift` of `splice` (`carat/domain/buffer.rb:652`, `:687`), displacing marks when a plugin edit is reverted inside `:g`; `HandleKey#timeout` drops the completion, hover, definition, and palette follow-ups of `call` (`carat/use_cases/handle_key.rb:170`, `:153`), leaving a float open after a timeoutlen binding moves the cursor. Fix outline: each path matches its sibling and Vim. Accepted when rows fail before and pass after in `test/editor_insert.rb` (a tab and a wide character before the cursor), `test/domain_keymap.rb` (a two-key `none`), `test/domain_global.rb` (a revert inside `:g`), and `test/editor_leader.rb` (a timeoutlen binding closes the hover). Backlog: "## Tab with expandtab pads by character column", "## A none unbinding turns an unbound key into an empty prefix", "## A rollback during :g leaves the global marks on the wrong rows", "### Buffer#revert_to leaves global marks unshifted", "## A key resolved by timeoutlen runs no follow tail".

## Pool

1. `brief-only-relay` (T1 pipeline, estimated medium, pushed back 3, S8 first, the user-approved exception): the workflow relays the user's latest chat message beside the brief (`.claude/workflows/deliver-change.js:945`), and the package start gets only the backlog handover and plan notes, not the brief (`.claude/workflows/deliver-change.js:1032`), so #137 pushed and merged before the user's reading; in the commit applying the sprint-8 queue it adds the "user-approved exception" marker `tools/docs_lint.sh:153` honors. Accepted when a case shows a start's prompt holds only the brief or resume brief, a case shows the brief, a hold-for-the-user instruction included, reaches every contributor start, the package start included, and docs-lint passes a marked sprint of 4 pipeline items and refuses an unmarked one.
2. `ci-time-tidy` (T1 pipeline defects, estimated large, pushed back 1, split at its start, S8): docs-only #130 spent 390 of 486 stage seconds on compile, test, bench; ci-stages drops fractional steps; `Makefile:79` stale; locally the checker ran 664 s of stages on docs-only #137 (diagnose 207, test-build 162), none checking a changed file; #138 spent 91 of 663 local stage s (13.7%) on tools-test, touching no file it tests. The user's outline: two CI workflows, no overlap: pull requests only (the full checks, the required check name `spin` kept), push to main only (measurement, compile-cache warming, release build and smoke test; the full checks only when the squash tree differs from the passed head, no compile when it is equal and cached); docs-only skips compile, test, bench. Accepted when a docs-only pull request runs only its paths' stages, its local check runs only docs-lint and gates in under 60 s, a change touching no file tools-test covers skips it locally and in CI, an equal-tree main push compiles nothing, and protection still sees `spin`.
3. `scout-focus` (T1 pipeline retrospective, estimated medium, pushed back 5, S8 by the user's order): scouts 16,826 of 89,979 output (18.7%, 14 calls) at #135, 32.1% at #134, 20.9% at #137 (11,705, 13 calls, a root LICENSE in no map area), against 472 and 1,397 at #130, #133 at rework 0 (`.claude/workflows/deliver-change.js:994`, `.claude/agents/scout.md` step 8). Accepted when three code changes spend under 15% of output and fewer calls than the contributor on scouts, a change in no map area starts no scout or spends under 2%, first passes unchanged. Backlog: "## The scout's step 8 says every Rules line names sections".
4. `sprint-tidy` (T1 pipeline defects, estimated medium, pushed back 1, split at its start, S8): a brief fixing the order still plans (#135 plan 14.9% of output), and a resume whose brief holds the main session's decisions starts a full planner (#136 41,075 of 242,766, 16.9%, 20 calls); history skips a never-merged row (`tools/run_state.sh:1372`); review-due counts a user-approved exception toward a sprint's five. Accepted when each fails in a case.
5. `spinel-notice` (T2 user request, docs, estimated small, S8, the user-approved exception): `tools/spinel/` carries a header generated from Spinel, but the credit at `README.md:212` names the MIT license without its copyright and permission notice (#137 advisory 2). Fix outline: add tools/spinel/LICENSE carrying Spinel's MIT copyright and permission notice, its copyright line without the email, and point the README credit at it; no URL, no email. Accepted when that file holds the notice, the README credit names it, and docs-lint and gates pass.
6. `markdown-reading-a` (T2 user now-request, part a, estimated medium, pushed back 5, S8 by the user's order): no key shows a Markdown buffer as readable text (measure, headings, lists, quotes); `carat/domain/markdown_text.rb:27` draws box cells under `option.icons ascii`, against `README.md:171`. Accepted when snapshots show the view and the toggle, no escape byte or ascii-set box cell is drawn, an over-cap document stays bounded, and `docs/actions.md` has the row.
7. `ruby-structure-check` (T2 user request, estimated medium, S9): the Ruby tokenizer flags an unclosed `def`, `class`, `module`, `do`, `if` at once, no language server. Accepted when a table test flags each opener and keys hold.
8. `git-signs-status` (T2 user request, estimated medium, S9): added, changed, deleted line signs; branch with ahead and behind in the status line.
9. `git-panel` plugin (T2 user request, estimated large, split at its start, S9): Unstaged, Staged, Recent; `s` stage, `u` unstage, `c` commit in a message buffer (`:wq` commits, empty aborts), `?` help, a confirmation before anything destructive.
10. `backlog-read-guard` (T1 pipeline, estimated small, S9): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (3 of 4 searching starts at #129). Accepted when a case refuses each read form and an append passes.
11. `gateway-split-a` (T5 architecture-review M1, estimated medium, S9): the gateway's 1,374 lines; `LspUri`, `Utf16Position`, `JsonRpcSession` first; folds `lsp-client-tidy` and the repeated reads and stale outline at `json_rpc_language_gateway.rb:469`, `:537`, `:931`.
12. `lint-panel` (T2 user request, estimated large, split at its start, S10): every diagnostic in a list, Enter jumps; rubocop state in the status line; quickfix `:grep :make :cnext :copen`.
13. `git-push-pull` (T2 user request, estimated medium, S10): `P` asks before a push, never force; `F` pulls.
14. `git-diff-blame` (T2 user request, estimated medium, S10): `=` diffs the file; a blame line.
15. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 2, S10): a planted `.git/objects` object substitutes main's content in the merge gates; scp origins accepted (Medium (5), `.claude/agents/merger.md:12`).
16. `frame-painters` (T5 architecture-review M2, estimated medium, S10): the presenter's 1,274 lines.
17. `language-any` (T2 user request, estimated medium, S11): `language.<name>.lsp` lines.
18. `vim-macros-marks` (T2 user request, estimated medium, S11).
19. `vim-case-increment` (T2 user request, estimated medium, S11).
20. `own-line-advisories` (T1 pipeline, estimated medium, S11): advisories on a change's own lines go to the backlog (#134 6 of 6, #133 3 of 3); the package start composes the handed entries (#138 package 7,995 output, 20 of 30 calls, its first append in the wrong form, redone; #137 advisory 1 the same). Accepted when every appended entry is a ### title with Location, Why, Fix lines and the package prompt carries no finding text to rewrite.
21. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11).
22. `vim-line-commands` (T2 user request, estimated medium, S12).
23. `vim-folds` (T2 user request, estimated medium, S12).
24. `markdown-reading-b` (T2 user now-request, part b, estimated medium, S12).
25. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes.
26. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
27. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
28. `formatting` (T5 roadmap 14, estimated medium, S13).
29. `ux-pass-2` (T2 user now-request, estimated medium, S13).
30. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13 by the guide): #135 merge 15,623 of 89,979 (17.4%), 6 of 13 calls waiting on a 13.0 min CI, 0 fixes; #132 16,313; #136 stored merged d180d78de192 for d180d78de199. Accepted when 3 green merges spend under 6,000 and wait in at most 2 calls, and the merged commit is taken from git and verified (`git rev-parse --verify`) before it is stored, a case refusing one that does not resolve.
31. `language-followers` (T5 architecture-review H2, estimated medium, S13).
32. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S14).
33. `release-build` (T5 roadmap 15, estimated medium, S14).
34. `sample-plugin` (T5 user-scheduled, estimated medium, S14).
35. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 3, S14): a merged name replayed #95 (120K): a delivery started under a change name already merged reuses that run's state. Accepted when a case refuses or fresh-starts a merged name.
36. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; #134's typed test reads; #135's advisories 1, 3, 4 (`docs/spinel-notes.md:47`); `test/lint.rb:255` arrays.
37. `dogfooding` (T2 user request, estimated medium, S15).
38. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15).
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
55. `ci-scope-quoting` (T1 pipeline, Low (6), estimated small, pushed back 3): `tools/ci_scope.sh:95`, `:78`.
56. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 3): quality 46/97 first pass; #136 3 blocking failure-path misses in new tooling; #138 2 of 3 advisories rows that pass before the change (`test/domain_theme.rb:453`, `:376`). Accepted above 60% over 10 changes and no such advisory over the next 5 code changes, no new start.
57. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
58. `run-resume` (T1 retrospective, estimated medium, pushed back 17).
59. `check-runner-safety` (T1 security, estimated medium, pushed back 15): sprint-6 sweep Medium (6) `run_state.sh:571`; `toolchain-clean`.
60. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
61. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): tag-pinned actions, `open-pr.yml:46`.
62. `project-config-guards` (T3, estimated medium, pushed back 23): a cloned `.caratrc` binds a write (`config.rb:221`).
63. `insert-copy` (T4, estimated small, pushed back 12).
64. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`; a sentence scenario.
65. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.
66. `architecture-docs` (T6, estimated small, pushed back 1): floats (M4); `wrap`, `clipboard`.
67. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
68. `ex-handlers-tidy` (T6 sweep, estimated medium): 6 sprint-6 findings, `history_command_handler.rb:44`.
69. `editing-counts` (T6, estimated medium, pushed back 11).
70. `hover-tidy` (T6, estimated medium, pushed back 13).
71. `signature-tidy` (T6, estimated medium, pushed back 12).
72. `slots-tidy` (T6, estimated medium, pushed back 12).
73. `completion-tidy` (T6, estimated medium, pushed back 14).
74. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
75. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
76. `definitions-tidy` (T6, estimated medium, pushed back 11).
77. `plugin-host-tidy` (T6 sweep, estimated medium, pushed back 1): `plugin_router.rb:40`.
78. `input-core-tidy` (T6 sweep, estimated medium, pushed back 1): longest bound prefix (`handle_key.rb:253`).
79. `ui-code-tidy` (T6 sweep, estimated medium, pushed back 1): #138 advisories `carat/domain/themes.rb:470` (a hand-rolled find), `test/domain_theme.rb:453`, `:376` (rows passing without the fix).
80. `tools-docs-tidy` (T6 sweep, estimated medium, pushed back 1): `docs/examples.md:25`, `:31`; `tools/docs_lint.sh:18`; `Makefile:303`; #136's 7 advisories (`Makefile:317`, `:87`, `tools/spinel_warnings.sh:42`); "### make types leaves build/carat.rbs that breaks every later compile", whose `- Fix:` and line-less Location drift from the entry format (#137 advisory 1).
81. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Guide

The user's guide (2026-11-15), security first and review findings adjusting it:

- S7, the user's composition: `spinel-warnings`, `mit-license`, `carat-palette-b`, `ux-pass`, `core-correctness`.
- S8, the user-approved speed-up exception to the one-pipeline limit and the 3/2 mix: `brief-only-relay`, `ci-time-tidy`, `scout-focus`, `sprint-tidy`, `spinel-notice`, `markdown-reading-a`.
- S9 to S15, the earlier S8 to S14 shifted one sprint, three features and two fixes each as the pool's sprint tags place them; `gate-object-pin` first in S10 if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Dropped: carat drawing its own glyphs (`nerd` stays an option); parallel lanes.

## Decisions

- `ux-pass` (T2 user now-request, pushed back 5) runs now, estimated medium: docs-only mit-license 636,713 total in 30 min plus a release build (62 s in CI) and pseudo-terminal screens; code rows 658,578 to 935,582, under medium's 1.2M; one review, no code, not split.
- S7 left: `core-correctness` (T6 periodic quality blocking=2 at 4958dc6bd923), the user's composition; mix deviation kept: 2 features, 3 fixes.
- `merged-name-guard` (T1, pool 35) restored to its 4958dc6 defect (#95 replayed a merged name, 120K) by the user's instruction; the merged-commit check (#136 d180d78de192) stays only in `merge-gate-integrity`; nothing reordered.
- #138 retro 4 (package 7,995 output, 20 of 30 calls, entry form redone; 2 of the last 2 runs) folded into `own-line-advisories` (T1, pool 20).
- #138 retro 5 (tools-test 91 of 663 local stage s, 13.7%, no tested file touched) folded into `ci-time-tidy` (T1, S8).
- #138 retro 6 (2 of 3 advisories rows passing before the change; quality 46/97) folded into `spec-tests-first` (T1, pool 56).
- #138 advisories 1 to 3 (`carat/domain/themes.rb:470`, `test/domain_theme.rb:453`, `:376`), appended by its package step, folded into `ui-code-tidy` (T6 sweep).
- #138 within budget: 750,242 total in 56 min, rework 0; #136's overrun (1,443,603) already reported.
- Security: none open at 8 or above; #138 0/0/0 at 37e1270c2aa7; pooled Mediums (7) `sprint-security`, `content-gate-gaps`.
- Pace: quality 46/97 first pass, ci 93/99, 86 rework rounds over 97 changes.
