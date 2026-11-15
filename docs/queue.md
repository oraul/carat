# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 6

1. `carat-palette-b` (T2 user now-request, estimated medium, pushed back 2): with `cursorline` on and `option.background terminal`, lit cells of groups without a foreground keep the terminal's foreground over the fixed stripe (`carat/domain/themes.rb:39`), dark on dark on a light terminal, and the contrast table checks only `background theme`; the lookup repeats `NAMES` as an if chain with a silent fallback and a dead `line_bg16` (`themes.rb:474`, `:545`); `from_palette` keeps `indexes256` BG and FG; five contrast tables list the palettes by hand (`test/domain_theme.rb:297`, `:11`); the Alias scenario names carat-light (`openspec/specs/color-themes/spec.md:49`, `test/domain_theme.rb:253`); comments past the width (`themes.rb:67`). Fix outline: lit cells take the palette's foreground over the terminal's background; one palette table drives the lookup and the tests. Accepted when a `test/domain_theme.rb` row holds 4.5:1 cursor-line text in every palette, background, and depth, the tables iterate the names, and a palette missing from the lookup fails. Backlog: "## The default cursor line keeps the terminal's foreground over a dark stripe", "## Themes.palette repeats NAMES as an if chain", "## from_palette leaves the 256-color background and foreground when the terminal paints", "## The theme test lists the palettes a second time", "## Themes misses a blank line and a comment near known?", "### The theme contrast tables list every palette by hand", "### The Alias scenario names a palette that is no alias", "### The theme palette lookup repeats NAMES and keeps a dead branch", "### Quality: reflowed comments run past the comment width, carat/domain/themes.rb:67".
2. `ux-pass` (T2 user now-request, estimated medium, pushed back 4, below the user's Spinel request by its written reason): no review of how carat feels in use is recorded; the gates measure code (quality 43/93 first pass), not use. Locations: the presenters `carat/adapters/frame_presenter.rb`, `status_bar.rb`, `tab_bar.rb`, `winbar.rb`, and `config/default.caratrc`. Accepted when a three-view review (Facet identity, other tools, a skeptic) of first use, empty and loading states, feedback on a failed key, messages, float consistency, and key-to-answer time is recorded in its archived change, each finding with a reproduction appended to `docs/backlog.md` for sprint 7's planning, no code changed. Backlog: none.

## Pool

1. `markdown-reading-a` (T2 user now-request, part a, estimated medium, pushed back 4, S7): one key toggles a read-only Markdown view (measure, headings, lists, quotes); `carat/domain/markdown_text.rb:27` draws box cells under `option.icons ascii`, against `README.md:171`. Accepted when snapshots show the view and toggle, no escape byte or ascii-set box cell drawn, an over-cap document bounded.
2. `brief-only-relay` (T1 pipeline, estimated medium, pushed back 2, S7): the workflow relays the user's latest chat message beside the brief (`.claude/workflows/deliver-change.js:945`). Accepted when a case shows a start's prompt holds only the brief or resume brief.
3. `ci-time-tidy` (T1 pipeline defects, estimated medium, S7): ci-stages drops fractional steps; `Makefile:79` stale; docs-only #130 spent 390 of 486 stage seconds on compile, test, bench. Accepted when such a change runs only its paths' stages.
4. `scout-focus` (T1 pipeline retrospective, estimated medium, pushed back 4, S7): scouts 32.1% of output at #134 (50,709 of 158,002, 43 of 191 calls, implement 81, 19 pack gaps, none the rebuild counts), 31.1% at #132, 44.9% at #129; #133 started no scout (1.3%) at rework 0. Accepted when three code changes spend under 15% and fewer calls than the contributor on scouts, first passes unchanged.
5. `sprint-tidy` (T1 pipeline defects, estimated medium, split at its start, S7): plan_needed plans a brief that fixes the order (#131 plan 22.2% of output); history skips a never-merged row (`tools/run_state.sh:1372`). Accepted when each fails in a case.
6. `ruby-structure-check` (T2 user request, estimated medium, S8): carat's Ruby tokenizer flags an unclosed `def`, `class`, `module`, `do`, `if` and the like at once, no language server. Accepted when a table test flags each opener and keys hold.
7. `git-signs-status` (T2 user request, estimated medium, S8): added, changed, deleted line signs; branch with ahead and behind in the status line.
8. `git-panel` plugin (T2 user request, estimated large, split at its start, S8): an explorer-like panel over the git command: Unstaged, Staged, Recent; `s` stage, `u` unstage, `c` commit in a message buffer with the staged summary (`:wq` commits, empty aborts), `?` help, a confirmation before anything destructive.
9. `backlog-read-guard` (T1 pipeline, estimated small, S8): `tools/agent_guard.sh` lets a delivery read `docs/backlog.md` (3 of 4 searching starts at #129). Accepted when a case refuses each read form and an append passes.
10. `gateway-split-a` (T5 architecture-review M1, estimated medium, S8): the gateway's 1,374 lines; the pure `LspUri` and `Utf16Position` helpers and `JsonRpcSession` first; folds `lsp-client-tidy` (unbounded queues Low (5)) and #134's duplicated reads (`json_rpc_language_gateway.rb:469` id in seven branches, `:1065`).
11. `lint-panel` (T2 user request, estimated large, split at its start, S9): every diagnostic, built-in and RuboCop, in a list, Enter jumps; rubocop on or off in the status line; quickfix `:grep :make :cnext :copen` joins it.
12. `git-push-pull` (T2 user request, estimated medium, S9): `P` asks "push <branch> -> origin?", progress and result in a float, never force; `F` pulls.
13. `git-diff-blame` (T2 user request, estimated medium, S9): `=` diffs the file; a blame line for the current line.
14. `gate-object-pin` (T1 pipeline security, estimated medium, pushed back 2, S9): a planted `.git/objects` object substitutes main's content in the merge gates; ssh and scp origins accepted (Medium (5), `.claude/agents/merger.md:12`). Accepted when such a case reads main's content and scp is refused.
15. `frame-painters` (T5 architecture-review M2, estimated medium, S9): the presenter's 1,274 lines paint floats, menus, messages inline.
16. `language-any` (T2 user request, estimated medium, S10): `language.<name>.lsp` lines start other language servers.
17. `vim-macros-marks` (T2 user request, estimated medium, S10): `q{a-z} @{a-z} @@`; `m{a-z} 'a` and backtick `a`, `''`.
18. `vim-case-increment` (T2 user request, estimated medium, S10): `g~ gu gU gq =` in normal mode; `<C-a> <C-x>`.
19. `own-line-advisories` (T1 pipeline, estimated medium, S10): advisories on lines a change wrote go to the backlog, #134 6 of 6 (one recorded twice), #133 3 of 3, #132 2 of 4, #130 5 of 5. Accepted when over three deliveries no appended entry cites its own diff's line, rework unchanged.
20. `gateway-split-b` (T5 architecture-review M1, estimated medium, S10): one class per request kind.
21. `vim-line-commands` (T2 user request, estimated medium, S11): `:m :t :normal :sort`.
22. `vim-folds` (T2 user request, estimated medium, S11): `zf za zo zc`.
23. `markdown-reading-b` (T2 user now-request, part b, estimated medium, S11): tables, links, heading jumps, outline, fences.
24. `hook-one-place` with budget-headroom (T1 pipeline, estimated medium, pushed back 1, S11): the guard hook in 10 lines of 9 agent files; `planner.md` 8,190 of 8,192 bytes, `CLAUDE.md` 30,692 of 30,720. Accepted when the hook resolves in one place and the next rule trims nothing outside its scope.
25. `plugin-api-split` (T5 architecture-review M3, estimated medium, S11): `carat/plugin_api.rb` 888 lines.
26. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S12): external plugins' protocol, part a.
27. `formatting` (T5 roadmap 14, estimated medium, S12): RuboCop through the language service.
28. `ux-pass-2` (T2 user now-request, estimated medium, S12): a second recorded use review.
29. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14, S12): merger over its cap 11 of 16 rows; #132 merge 16,313 output (12.0%) on a clean run; the CI wait scales calls with CI minutes (#134 6 of 13 at 8.3 min, #133 8 of 13 at 15.0, #125 to #132 4 to 6 at 6.1 to 11.0). Accepted when 3 green merges spend under 6,000 and wait in at most 2 calls.
30. `language-followers` (T5 architecture-review H2, estimated medium, S12): `input_controller.rb:62`, `handle_key.rb:92`; the assembly grouping.
31. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S13).
32. `release-build` (T5 roadmap 15, estimated medium, S13).
33. `sample-plugin` (T5 user-scheduled, estimated medium, S13): a first external plugin.
34. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 3, S13): a merged name replayed #95 (120K).
35. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S13): 5 workarounds at the pin `spinel-untyped-bump-b` sets; `json.rb:72`; folds #134's typed reads: `test/editor_grammar.rb:47` untyped `move_to` in 15 test files, `test/domain_grammar.rb:15` two reader forms, `carat/doubles/fake_processes.rb:69`, `docs/spinel-notes.md:47` reader advice.
36. `dogfooding` (T2 user request, estimated medium, S14): carat edits carat; fix what use finds.
37. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 4, S14): `reRaised` demotes a blocker.
38. `language-ask-port` (T5 architecture-review H1, estimated medium, S14): `hover_request.rb`.
39. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
40. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
41. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
42. `finder-grep` (T5 user request, estimated medium, pushed back 6).
43. `definition-tab` (T5 user request, estimated medium, pushed back 6): `<C-w>gd`.
44. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
45. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
46. `filetype-rules` (T5 user request, estimated medium, pushed back 6): `filetype.rb:29`.
47. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).
48. `syntax-forms` (T5 user request, estimated medium, pushed back 6).
49. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).
50. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).
51. `html-syntax` (T5 user request, estimated medium, pushed back 6).
52. `sprint-security` (T1 pipeline security, estimated medium, pushed back 3): partial review grooms, Medium (7) `sprint-planning.js:121`.
53. `content-gate-gaps` (T1 security, estimated medium, pushed back 15): binary files skipped, Medium (7); `gates.sh:224`.
54. `ci-scope-quoting` (T1 pipeline, Low (6), estimated small, pushed back 3): `tools/ci_scope.sh:95`.
55. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 3): quality 43/93 first pass.
56. `open-pr-refusals` (T1 security Lows, estimated medium, pushed back 3): `tools/open_pr.sh:180`.
57. `run-resume` (T1 retrospective, estimated medium, pushed back 17): resumes rerun plan and scouts.
58. `check-runner-safety` (T1 security Lows, estimated medium, pushed back 15): `run_state.sh:571`.
59. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
60. `ci-hardening` (T3 with T6, estimated medium, pushed back 23): tag-pinned actions.
61. `project-config-guards` (T3, estimated medium, pushed back 23): a cloned `.caratrc` binds a write.
62. `insert-copy` (T4, estimated small, pushed back 12).
63. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `tools/metrics.sh:30`.
64. `file-access-tidy` (T4 with T6, estimated medium, pushed back 26).
65. `architecture-docs` (T6, estimated small, pushed back 1): floats (M4); #131's lost facts.
66. `periodic-blockers-b` (T6 periodic quality, estimated medium, pushed back 8).
67. `editing-counts` (T6, estimated medium, pushed back 11): `motions.rb:488`.
68. `hover-tidy` (T6, estimated medium, pushed back 13).
69. `signature-tidy` (T6, estimated medium, pushed back 12).
70. `slots-tidy` (T6, estimated medium, pushed back 12).
71. `completion-tidy` (T6, estimated medium, pushed back 14): 32 findings.
72. `completion-docs-tidy` (T6, estimated medium, pushed back 14).
73. `buffer-list-tidy` (T6, estimated medium, pushed back 16).
74. `definitions-tidy` (T6, estimated medium, pushed back 11).
75. `plugin-host-tidy` (T6 sweep, estimated medium, pushed back 1).
76. `input-core-tidy` (T6 sweep, estimated medium, pushed back 1).
77. `ui-code-tidy` (T6 sweep, estimated medium, pushed back 1): `frame_presenter.rb:266`; #133's `tab_page.rb:68` rule beside the mode, `window.rb:23` winbar flag name, `test/editor_breadcrumbs.rb:209` auto row.
78. `tools-docs-tidy` (T6 sweep, estimated medium, pushed back 1): #131's 4; #132's `docs/examples.md:31`, `tools/new.sh:280`, `:275`, `config-files/spec.md:27`.
79. `docs-index` (T6, estimated medium, pushed back 21, split at its start).

## Guide

The user's 9-sprint guide (2026-11-15), the direction each sprint's planning follows, security first and review findings adjusting it; pool items carry their sprint:

- S6 features `winbar-outline`, `carat-palette-b`, `ux-pass`; fixes `design-principles`, `architecture-tidy` (done).
- S7, a one-time exception to the one-pipeline limit and the 3/2 mix: `markdown-reading-a`; `brief-only-relay`, `ci-time-tidy`, `scout-focus`, `sprint-tidy`.
- S8 `ruby-structure-check`, `git-signs-status`, `git-panel`; `backlog-read-guard`, `gateway-split-a`.
- S9 `lint-panel`, `git-push-pull`, `git-diff-blame`; `gate-object-pin` (first if rated T0), `frame-painters`.
- S10 `language-any`, `vim-macros-marks`, `vim-case-increment`; `own-line-advisories`, `gateway-split-b`.
- S11 `vim-line-commands`, `vim-folds`, `markdown-reading-b`; `hook-one-place`, `plugin-api-split`.
- S12 `plugin-protocol-a`, `formatting`, `ux-pass-2`; `merge-gate-integrity`, `language-followers`.
- S13 `plugin-protocol-b`, `release-build`, `sample-plugin`; `merged-name-guard`, `spinel-workarounds`.
- S14 `dogfooding` and two that S6 to S13 reveal; `review-demotion`, `language-ask-port`.
- Dropped: carat drawing its own glyphs; `nerd` stays an option, not deprecated.

## Decisions

- `spinel-untyped-bump-b` (T2, the user's Spinel bump, part b) is delivered now, estimated medium: `spinel-rebump` 862,013 in 177 min and part a 935,582 in 79 min, both under the 1.2M budget; one pin move with its header, nine Symbol entries, and notes, not split.
- Sprint 6 keeps `carat-palette-b` then `ux-pass`, no reorder (the brief); parts a (#134) and b sit outside the 3/2 mix as the user's request.
- Security: none open at 8 or above; #134 security 0/0/0 at 7dce6bc1a265; highest pooled Medium (7) (`sprint-security`, `content-gate-gaps`).
- #134 quality advisories 1 and 2 (T6, gateway duplication) fold into `gateway-split-a`; 3 to 7 (T6, typed reads in tests, `docs/spinel-notes.md:47`) into `spinel-workarounds`, the Spinel domain.
- #134 retro 8 (T1, scouts 32.1% of output) folds into `scout-focus`; 9 (T1, 6 of 6 own-diff) into `own-line-advisories`; 10 (T1, 6 of 13 merge calls waiting at 8.3 min) into `merge-gate-integrity`.
- `spinel-warnings`, which the brief names next after this, has no queue item; none added without its problem and the user's word, the brief forbidding a reorder.
- Carried: S7's four pipeline fixes fail `tools/docs_lint.sh:153` (at most 1) and need the user's word on a change before sprint 7's planning.
- Pace: quality 43/93 first pass, security 88/93, ci 90/96; #134 rework 0, 935,582 total in 79 min.
