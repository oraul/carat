# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 7

1. `carat-palette-b` (T2 user now-request, feature, estimated medium, pushed back 3, carried from sprint 6): with `cursorline` on and `option.background terminal`, lit cells of groups without a foreground keep the terminal's foreground over the fixed stripe (`carat/domain/themes.rb:39`), dark on dark on a light terminal, and the contrast table checks only `background theme`; the lookup repeats `NAMES` as an if chain with a silent fallback and a dead `line_bg16` (`themes.rb:474`, `:545`); `from_palette` keeps `indexes256` BG and FG; five contrast tables list the palettes by hand (`test/domain_theme.rb:297`, `:11`); the Alias scenario names carat-light (`openspec/specs/color-themes/spec.md:49`, `test/domain_theme.rb:253`); comments past the width (`themes.rb:67`). Fix outline: lit cells take the palette's foreground over the terminal's background; one palette table drives the lookup and the tests. Accepted when a `test/domain_theme.rb` row holds 4.5:1 cursor-line text in every palette, background, and depth, the tables iterate the names, and a palette missing from the lookup fails. Backlog: "## The default cursor line keeps the terminal's foreground over a dark stripe", "## Themes.palette repeats NAMES as an if chain", "## from_palette leaves the 256-color background and foreground when the terminal paints", "## The theme test lists the palettes a second time", "## Themes misses a blank line and a comment near known?", "### The theme contrast tables list every palette by hand", "### The Alias scenario names a palette that is no alias", "### The theme palette lookup repeats NAMES and keeps a dead branch", "### Quality: reflowed comments run past the comment width, carat/domain/themes.rb:67".
2. `ux-pass` (T2 user now-request, feature, estimated medium, pushed back 5, carried from sprint 6): no review of how carat feels in use is recorded; the gates measure code (quality 45/95 first pass), not use. Locations: the presenters `carat/adapters/frame_presenter.rb`, `status_bar.rb`, `tab_bar.rb`, `winbar.rb`, and `config/default.caratrc`. Accepted when a three-view review (Facet identity, other tools, a skeptic) of first use, empty and loading states, feedback on a failed key, messages, float consistency, and key-to-answer time is recorded in its archived change, each finding with a reproduction appended to `docs/backlog.md` for sprint 9's planning, no code changed. Backlog: none.
3. `core-correctness` (T6 periodic quality blocking, fix, estimated medium): four editing bugs the sprint-6 sweep raised again (blocking=2 at 4958dc6bd923): Tab under `expandtab` pads from the code-point column, so after a tab or a wide character it stops off the stop (`carat/use_cases/insert_tab.rb:23`; ts=4 after a tab and x lands on display column 7, not 8; the one test, `test/editor_insert.rb:64`, types after ASCII); a `none` unbinding walks with `child_for` and leaves empty trie nodes, so `keymap.normal xy none` makes `x` wait timeoutlen or with no deadline (`carat/domain/keymap.rb:228`); `Buffer#revert_to` skips the `global_marks.shift` of `splice` (`carat/domain/buffer.rb:652`, `:687`), displacing marks when a plugin edit is reverted inside `:g`; `HandleKey#timeout` drops the completion, hover, definition, and palette follow-ups of `call` (`carat/use_cases/handle_key.rb:170`, `:153`), leaving a float open after a timeoutlen binding moves the cursor. Fix outline: each path matches its sibling and Vim. Accepted when rows fail before and pass after in `test/editor_insert.rb` (a tab and a wide character before the cursor), `test/domain_keymap.rb` (a two-key `none`), `test/domain_global.rb` (a revert inside `:g`), and `test/editor_leader.rb` (a timeoutlen binding closes the hover). Backlog: "## Tab with expandtab pads by character column", "## A none unbinding turns an unbound key into an empty prefix", "## A rollback during :g leaves the global marks on the wrong rows", "### Buffer#revert_to leaves global marks unshifted", "## A key resolved by timeoutlen runs no follow tail".

## Pool

1. `brief-only-relay` (T1 pipeline, estimated medium, pushed back 3, S8 first, the user-approved exception): the workflow relays the user's latest chat message beside the brief (`.claude/workflows/deliver-change.js:945`); in the commit applying the sprint-8 queue it adds the "user-approved exception" marker `tools/docs_lint.sh:153` honors. Accepted when a case shows a start's prompt holds only the brief or resume brief, and docs-lint passes a marked sprint of 4 pipeline items and refuses an unmarked one.
2. `ci-time-tidy` (T1 pipeline defects, estimated large, pushed back 1, split at its start, S8): docs-only #130 spent 390 of 486 stage seconds on compile, test, bench; ci-stages drops fractional steps; `Makefile:79` stale. The user's outline: two CI workflows, no overlap: pull requests only (the full checks, the required check name `spin` kept), push to main only (measurement, compile-cache warming, release build and smoke test; the full checks only when the squash tree differs from the passed head, no compile when it is equal and cached); docs-only skips compile, test, bench. Accepted when a docs-only pull request runs only its paths' stages, an equal-tree main push compiles nothing, and protection still sees `spin`.
3. `scout-focus` (T1 pipeline retrospective, estimated medium, pushed back 5, S8 by the user's order): scouts 16,826 of 89,979 output (18.7%, 14 calls) at #135, 32.1% at #134, against 472 and 1,397 at #130, #133 at rework 0 (`.claude/workflows/deliver-change.js:994`, `.claude/agents/scout.md` step 8). Accepted when three code changes spend under 15% of output and fewer calls than the contributor on scouts, first passes unchanged. Backlog: "## The scout's step 8 says every Rules line names sections".
4. `sprint-tidy` (T1 pipeline defects, estimated medium, pushed back 1, split at its start, S8): a brief fixing the order still plans (#135 plan 14.9% of output), and a resume whose brief holds the main session's decisions starts a full planner (#136 41,075 of 242,766, 16.9%, 20 calls); history skips a never-merged row (`tools/run_state.sh:1372`); review-due counts a user-approved exception toward a sprint's five. Accepted when each fails in a case.
5. `markdown-reading-a` (T2 user now-request, part a, estimated medium, pushed back 5, S8 by the user's order): no key shows a Markdown buffer as readable text (measure, headings, lists, quotes); `carat/domain/markdown_text.rb:27` draws box cells under `option.icons ascii`, against `README.md:171`. Accepted when snapshots show the view and the toggle, no escape byte or ascii-set box cell is drawn, an over-cap document stays bounded, and `docs/actions.md` has the row.
6. `ruby-structure-check` (T2 user request, estimated medium, S9): the Ruby tokenizer flags an unclosed `def`, `class`, `module`, `do`, `if` at once, no language server. Accepted when a table test flags each opener and keys hold.
7. `git-signs-status` (T2 user request, estimated medium, S9): added, changed, deleted line signs; branch with ahead and behind in the status line.
8. `git-panel` plugin (T2 user request, estimated large, split at its start, S9): Unstaged, Staged, Recent; `s` stage, `u` unstage, `c` commit in a message buffer (`:wq` commits, empty aborts), `?` help, a confirmation before anything destructive.
9. `backlog-read-guard` (T1 pipeline, estimated small, S9): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (3 of 4 searching starts at #129). Accepted when a case refuses each read form and an append passes.
10. `gateway-split-a` (T5 architecture-review M1, estimated medium, S9): the gateway's 1,374 lines; `LspUri`, `Utf16Position`, `JsonRpcSession` first; folds `lsp-client-tidy` and the repeated reads and stale outline at `json_rpc_language_gateway.rb:469`, `:537`, `:931`.
11. `lint-panel` (T2 user request, estimated large, split at its start, S10): every diagnostic in a list, Enter jumps; rubocop state in the status line; quickfix `:grep :make :cnext :copen`.
12. `git-push-pull` (T2 user request, estimated medium, S10): `P` asks before a push, never force; `F` pulls.
13. `git-diff-blame` (T2 user request, estimated medium, S10): `=` diffs the file; a blame line.
14. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 2, S10): a planted `.git/objects` object substitutes main's content in the merge gates; scp origins accepted (Medium (5), `.claude/agents/merger.md:12`).
15. `frame-painters` (T5 architecture-review M2, estimated medium, S10): the presenter's 1,274 lines.
16. `language-any` (T2 user request, estimated medium, S11): `language.<name>.lsp` lines.
17. `vim-macros-marks` (T2 user request, estimated medium, S11).
18. `vim-case-increment` (T2 user request, estimated medium, S11).
19. `own-line-advisories` (T1 pipeline, estimated medium, S11): advisories on a change's own lines go to the backlog (#134 6 of 6, #133 3 of 3).
20. `gateway-split-b` (T5 architecture-review M1, estimated medium, S11).
21. `vim-line-commands` (T2 user request, estimated medium, S12).
22. `vim-folds` (T2 user request, estimated medium, S12).
23. `markdown-reading-b` (T2 user now-request, part b, estimated medium, S12).
24. `hook-one-place` (T1 pipeline, estimated medium, pushed back 1, S12): `planner.md` 8,190 of 8,192 bytes.
25. `plugin-api-split` (T5 architecture-review M3, estimated medium, S12).
26. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
27. `formatting` (T5 roadmap 14, estimated medium, S13).
28. `ux-pass-2` (T2 user now-request, estimated medium, S13).
29. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S13 by the guide): #135 merge 15,623 of 89,979 (17.4%), 6 of 13 calls waiting on a 13.0 min CI, 0 fixes; #132 16,313. Accepted when 3 green merges spend under 6,000 and wait in at most 2 calls.
30. `language-followers` (T5 architecture-review H2, estimated medium, S13).
31. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S14).
32. `release-build` (T5 roadmap 15, estimated medium, S14).
33. `sample-plugin` (T5 user-scheduled, estimated medium, S14).
34. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 3, S14): #136 stored merged d180d78de192, which does not resolve (d180d78de199). Accepted when a case refuses a merged value `git rev-parse --verify` rejects.
35. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; #134's typed test reads; #135's advisories 1, 3, 4 (`docs/spinel-notes.md:47`); `test/lint.rb:255` arrays.
36. `dogfooding` (T2 user request, estimated medium, S15).
37. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S15).
38. `language-ask-port` (T5 architecture-review H1, estimated medium, S15).
39. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
40. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
41. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
42. `finder-grep` (T5 user request, estimated medium, pushed back 6).
43. `definition-tab` (T5 user request, estimated medium, pushed back 6).
44. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
45. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
46. `filetype-rules` (T5 user request, estimated medium, pushed back 6).
47. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).
48. `syntax-forms` (T5 user request, estimated medium, pushed back 6).
49. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).
50. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).
51. `html-syntax` (T5 user request, estimated medium, pushed back 6).
52. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): Medium (7) `sprint-planning.js:121`.
53. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): Medium (7) `gates.sh:224`.
54. `ci-scope-quoting` (T1 pipeline, Low (6), estimated small, pushed back 3): `tools/ci_scope.sh:95`, `:78`.
55. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 3): quality 45/95 first pass; #136 3 blocking failure-path misses in new tooling. Accepted above 60% over 10 changes, no new start.
56. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3).
57. `run-resume` (T1 retrospective, estimated medium, pushed back 17).
58. `check-runner-safety` (T1 security, estimated medium, pushed back 15): sprint-6 sweep Medium (6) `run_state.sh:571`; `toolchain-clean`.
59. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
60. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): tag-pinned actions, `open-pr.yml:46`.
61. `project-config-guards` (T3, estimated medium, pushed back 23): a cloned `.caratrc` binds a write (`config.rb:221`).
62. `insert-copy` (T4, estimated small, pushed back 12).
63. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`; a sentence scenario.
64. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26): `open_file.rb:62`.
65. `architecture-docs` (T6, estimated small, pushed back 1): floats (M4); `wrap`, `clipboard`.
66. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
67. `ex-handlers-tidy` (T6 sweep, estimated medium): 6 sprint-6 findings, `history_command_handler.rb:44`.
68. `editing-counts` (T6, estimated medium, pushed back 11).
69. `hover-tidy` (T6, estimated medium, pushed back 13).
70. `signature-tidy` (T6, estimated medium, pushed back 12).
71. `slots-tidy` (T6, estimated medium, pushed back 12).
72. `completion-tidy` (T6, estimated medium, pushed back 14).
73. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
74. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
75. `definitions-tidy` (T6, estimated medium, pushed back 11).
76. `plugin-host-tidy` (T6 sweep, estimated medium, pushed back 1): `plugin_router.rb:40`.
77. `input-core-tidy` (T6 sweep, estimated medium, pushed back 1): longest bound prefix (`handle_key.rb:253`).
78. `ui-code-tidy` (T6 sweep, estimated medium, pushed back 1).
79. `tools-docs-tidy` (T6 sweep, estimated medium, pushed back 1): `docs/examples.md:25`, `:31`; `tools/docs_lint.sh:18`; `Makefile:303`; #136's 7 advisories (`Makefile:317`, `:87`, `tools/spinel_warnings.sh:42`); "### make types leaves build/carat.rbs that breaks every later compile".
80. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Guide

The user's guide (2026-11-15), security first and review findings adjusting it:

- S7, the user's composition: `spinel-warnings`, `mit-license`, `carat-palette-b`, `ux-pass`, `core-correctness`.
- S8, the user-approved speed-up exception to the one-pipeline limit and the 3/2 mix: `brief-only-relay`, `ci-time-tidy`, `scout-focus`, `sprint-tidy`, `markdown-reading-a`.
- S9 to S15, the earlier S8 to S14 shifted one sprint, three features and two fixes each as the pool's sprint tags place them; `gate-object-pin` first in S10 if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Dropped: carat drawing its own glyphs (`nerd` stays an option); parallel lanes.

## Decisions

- `mit-license` (T2 user request, S7 head after #136) runs now, estimated medium: docs-only `design-principles` 722,832 and `architecture-review` 742,932 total, none under small's 500k; 3 parts, not split; held for the user before the push.
- S7 left: `carat-palette-b`, `ux-pass`, `core-correctness`, the user's order; mix deviation kept: 2 features, 3 fixes.
- S8 stays the user-approved exception (4 pipeline, 1 feature); its first delivery adds the marker `tools/docs_lint.sh:153` honors.
- #136 overrun: 1,443,603 total in 100 min over medium's 1.2M; implement 204,399 output over 200,000; merge 14 calls over 12; reported, not queued.
- #136 retro 12 (merged d180d78de192 unresolved) to `merged-name-guard`; 13 (plan 16.9%) to `sprint-tidy`; 14 (quality 45/95) to `spec-tests-first`.
- #136 blocking notes 1-3 fixed before d180d78de199; advisories 4-10, in the backlog, and the brief's `make types` entry go to `tools-docs-tidy` (T6).
- Security: none open at 8 or above; #136 0/0/0 at 079f6c60f970; pooled Mediums (7) `sprint-security`, `content-gate-gaps`.
- Pace: quality 45/95 first pass, ci 92/98; #136 rework 1.
