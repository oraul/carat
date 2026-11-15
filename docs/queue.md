# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 5

1. `untyped-gateway` (T2 user request, estimated medium, the user's word, sprint 5's third merge after `guard-ref-pin` and `guard-pin-no-url`): the largest compile-time cost left (test-build 141 s, diagnose 172 s, CI `compile_the_tests` 137 s at #124, 105 s at #125, 103 s at #126; runner analysis 87.4 s against carat's 40.3 s at #126) is removed with behavior unchanged; of 1,181 runner rebuilds at #124, the gateway's JSON reads (`carat/adapters/json_rpc_language_gateway.rb`) caused 210 and the language-server tests' indexing 366. Fix outline: measure first, remove the largest cause. Accepted when that cost falls, measured before and after, every stage green. Backlog: none.
2. `carat-glyphs` (T2 user now-request, estimated medium, pushed back 4, the user's word): the default `option.icons nerd` (`config/default.caratrc:27`, `carat/domain/icons.rb:11`) needs a patched font, so a stock font shows boxes for its 33 names; under `ascii` the separators and progress bar stay box drawing (`carat/adapters/frame_presenter.rb:102`, `:104`, `carat/adapters/status_bar.rb:319`). Accepted when a table-driven test finds every default glyph one cell wide outside the Private Use Areas, `nerd` stays selectable, and an `ascii` frame holds no byte above 127. Backlog: "## Window separators and the progress bar ignore option.icons ascii".
3. `architecture-review` (T2 user request, estimated medium, the user's word, sprint 5's fifth merge): "review the architecture and the holes in it... it should be expansible, easy to read and do maintenance, sometimes something became redundant there". The sprint-4 sweep's duplication and dead-code entries (`docs/backlog.md`, "## Findings of the sprint-4 review and sweep") are inputs, not its scope. Accepted when a recorded report checks `docs/architecture.md` and `docs/codebase-map.md` against the code for holes (a feature with no extension point, a rule the code breaks, a missing port or seam), redundancy (two mechanisms for one job, dead code, docs repeating or contradicting each other), and reading or maintenance costs, each with its location, why, and a fix outline, each queued; the doc is corrected where it disagrees with the code; no fix lands. Backlog: none.

## Pool

1. `brief-only-relay` (T1 pipeline, user-approved, estimated medium, pushed back 1, sprint 6's pipeline slot: `guard-pin-no-url` took sprint 5's): the workflow relays the user's latest chat message to its agents beside the main session's brief (`.claude/workflows/deliver-change.js:945` builds the brief), so text the brief left out reaches every start. Accepted when every agent start receives only the brief or resume brief, a case showing no other user text in a start's prompt. Backlog: none.
2. `winbar-outline` (T2 user now-request, part b of `top-rows`, estimated medium, pushed back 4): `stop` (`carat/adapters/json_rpc_language_gateway.rb:242`, called by `restart` at `:222`) keeps a symbol request in flight, so after `:LspRestart` a stale answer replaces the outline; `FramePresenter` (`frame_presenter.rb:265`) and `ArrangeView` (`carat/use_cases/arrange_view.rb:50`) each decide which windows get a winbar; a split from a scratch window has no winbar row; `symbol_outline.rb:12` says characters where the cut is in bytes. Accepted when a `test/editor_breadcrumbs.rb` row keeps the new outline after `:LspRestart` with a request in flight, a scratch split has its row, one owner decides. Backlog: "## :LspRestart lets a stale symbol answer replace the outline", "## The presenter and the arranger each decide which windows get a winbar", "## A split from a scratch window has no winbar row", "## SymbolOutline's comment says characters where the cut is in bytes".
3. `gate-object-pin` (T1 pipeline security, unrated, estimated medium): a planted or overwritten object under `.git/objects` can still substitute content in the merge gates' worktree of `origin/main`, the route #126 closed for the hooks, where its security review blocked on it (1 blocking at f377ec3). Accepted when a case plants such an object and the merge gates refuse or read main's true content. Backlog: the security entry `guard-pin-no-url` appends.
4. `hook-one-place` (T1 retrospective, estimated medium): the guard hook is one command copied into 10 lines over 9 agent files under docs-lint byte budgets; #126's 3 rounds each edited all 10 and trimmed `planner.md` (8132 of 8192) and `contributor.md` (6939 of 6999), 4 of 15 quality notes were about trims, implement 45.3% of output. Accepted when a change to how hooks resolve the guard edits one place and moves no agent file's byte count.
5. `scout-focus` (T1 retrospective, estimated medium, pushed back 3, kept T1 as the highest tier below T0, passed by a security route and the hook fix): scouts 44.2% of output at #117, 31.7% and 39 of 173 calls at #124, 15.6% at #125; #119's split left a pack on the undelivered part (`deliver-change.js:975`); a #117 scout went 33 calls over its cap (`:103`) with no pack. Accepted when the next three editor changes spend under 15% on scouts, a run whose brief cites every edited line none, a split's packs cover its delivered part, a capped scout leaves its pack.
6. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 2): `/deliver` with a merged name replayed #95's run (about 120K tokens), resetting `metric.rework`. Accepted when refused unless an explicit resume, no run state written, in a case.
7. `carat-palette-b` (T2 user now-request, estimated medium, pushed back 1): under `background terminal` lit cursor-line cells keep the terminal's foreground (`carat/domain/themes.rb:39`); #121's 2 advisories; sprint-4's 4 theme advisories (`themes.rb:474`, `:545`, `test/domain_theme.rb:297`, `color-themes/spec.md:49`). Accepted when a `test/domain_theme.rb` row holds 4.5:1 in every palette and depth. Backlog: "## The default cursor line keeps the terminal's foreground over a dark stripe".
8. `ci-scope-quoting` (T1 pipeline defect with a security Low (6), estimated small, pushed back 1): sweep blocking `tools/ci_scope.sh:95` (a path holding a space or a glob is judged in pieces, CI skipped); `.github/workflows/ci.yml:58` runs the branch's own scope script (Low (6)); 5 ci_scope backlog entries of #125. Accepted when a code path with a space or glob runs CI and main's script decides, in cases.
9. `sprint-security` (T1 pipeline security, estimated medium, pushed back 1): a partial or not-run sprint review still grooms (Medium (7), `sprint-planning.js:121`); findings only through the skeptic (`:113`); groom drops a security entry on any ancestor (Low (6)); a forged sprint row (Low (5)); the sweep report (`:179`) and area-count slices (`periodic-review.js:65`, area 1 never read). Accepted when each refuses or records partial in a case.
10. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 3): `reRaised` demotes a blocking finding at an earlier advisory's line (#109); duplicate records (#118, #123, and #126's notes 7 to 11 repeating notes 2 to 6, reviews 34.4% of output); #122's fix round re-reviewed all (29.5%). Accepted when each holds in a case, a fix round records no advisory an earlier commit recorded, reviews under 31,000 output in a one-round run.
11. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 1): #113, #115, #118 blocked on their own untested delta spec; #121's 2 unproved scenarios; #126 deferred a route its implement note named, then blocked at security (fix round 73,089 output, over budget); quality first 36/85, security 81/85. Accepted when 4 of 5 deliveries pass quality first and no blocking security finding repeats a route the contributor's note named.
12. `ux-pass` (T2 user now-request, estimated medium, pushed back 3): a three-view review of how carat feels, each finding queued.
13. `markdown-reading` (T2 user now-request, estimated large, pushed back 3): one key toggles a read-only view, no raw escape.
14. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 3): a live split preview on 13's renderer.
15. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 3): layered box text, bounded.
16. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 3): on 15's caps.
17. `finder-grep` (T5 user request, estimated medium, pushed back 5): a live grep picker.
18. `definition-tab` (T5 user request, estimated medium, pushed back 5): `<C-w>gd` in a new tab page.
19. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5): 5 workarounds; `Utf8.boundary` guards untested; advisories of #120, #123, #124; sweep's `testing.rb:66`, `test/domain_selection.rb:47`, `editor_harness.rb:190` typing findings.
20. `finder-pickers` (T5 user request, estimated medium, pushed back 5): recent-file and buffer pickers.
21. `periodic-blockers-b` (T6 periodic quality blocking, estimated medium, pushed back 7): 4 periodic blocking findings.
22. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 9): an aligned view-only table.
23. `filetype-rules` (T5 user request, estimated medium, pushed back 5): `filetype.*` lines; sweep `filetype.rb:29`.
24. `syntax-definitions` (T5 user request, estimated medium, pushed back 5): a generated Python definition.
25. `syntax-forms` (T5 user request, estimated medium, pushed back 5): Python and Java forms.
26. `syntax-embedded` (T5 user request, estimated medium, pushed back 5): fences in any language.
27. `javascript-syntax` (T5 user request, estimated medium, pushed back 5): templates, regex against division.
28. `html-syntax` (T5 user request, estimated medium, pushed back 5): tags, attributes, entities.
29. `sprint-tidy` (T1 pipeline defects, estimated medium, split at its start): plan_needed takes an unreviewed plan; a sixth merge reviewed twice; history skips a never-merged row (`run_state.sh:1372`); dictated plans 31.3% of output at #125; the package step opened the backlog to copy its form (#125 note 10). Accepted when each fails in a case, a dictated plan under 15%.
30. `ci-time-tidy` (T1 pipeline defects, estimated medium): ci-stages drops fractional steps, cuts names at 33; `Makefile:79` stale. Accepted when each fails in a case, CI under 9 min or its floor noted.
31. `open-pr-refusals` (T1 with security Lows, estimated medium, pushed back 2): refusals without a case; scanner exit 2 passes; fork heads counted (Low (5), `open_pr.sh:180`); `WAIT_STEP=0` polls forever (`:121`); the body-fix race (`deliver-change.js:1102`). Accepted when each refuses in a case.
32. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14): merger over its cap in 11 of 16 rows; `phase.merge` unlike `merged` in 12 of 75. Accepted when each has a case, wait calls 4 or fewer.
33. `run-resume` (T1 retrospective, estimated medium, pushed back 16): #115's resume reran plan and scouts (46.6%). Accepted when a resume starts at its first unfinished phase.
34. `check-runner-safety` (T1 with security Lows, estimated medium, pushed back 14): unlocked writes, a lost runner, a writable shared toolchain (Low (5), `run_state.sh:571`). Accepted when each has a case.
35. `content-gate-gaps` (T1 with security findings, estimated medium, pushed back 14): binary files skipped (Medium (7)); scanner errors read clean; `gates.sh:224` fails open on a space. Accepted when each refuses.
36. `bidi-controls` (T3 security Lows, estimated small, pushed back 10): bidi and C0 bytes reach the terminal (Low (5)).
37. `ci-hardening` (T3 with T6 folded, estimated medium, pushed back 22): actions pinned by tag (Low (5)); 6 Lows.
38. `project-config-guards` (T3 with blocking, estimated medium, pushed back 22): a cloned `.caratrc` binds a write (Low (5)).
39. `insert-copy` (T4 periodic quality, estimated small, pushed back 11): a long insert copies per key.
40. `bench-scenarios` (T4 tests, estimated small): `palette` and `lh-winbar` skipped by `tools/metrics.sh:30` and `bench/run.sh:69`; `metrics.sh:86` passes a missing figure. Accepted when every scenario runs and a missing one fails.
41. `file-access-tidy` (T4 with T6 folded, estimated medium, pushed back 25): two 64 MiB strings per run; a link race (Low (3)); sweep `list_tree.rb:67`, `:98`, `resolve_inside.rb:41`.
42. `editing-counts` (T6 with blocking, estimated medium, pushed back 10): typed count and `:undo N` uncapped; sentence motions freeze on a huge count (sweep blocking `motions.rb:488`); `buffer.rb:652` revert skips global marks.
43. `hover-tidy` (T6 folded, estimated medium, pushed back 12): stale K answers and floats.
44. `signature-tidy` (T6 with blocking, estimated medium, pushed back 11): a `(` scan by bytes.
45. `slots-tidy` (T6 with blocking and a Low, estimated medium, pushed back 11): a hidden cursor outlives its buffer.
46. `completion-tidy` (T6 folded, estimated medium, pushed back 13): 32 findings.
47. `completion-docs-tidy` (T6 with a Low, estimated medium, pushed back 13): wrong-server resolve (Low (3)).
48. `buffer-list-tidy` (T6 with a Low, estimated medium, pushed back 15): a name forges `:ls` (Low (4)).
49. `lsp-client-tidy` (T6 with Lows, estimated medium, pushed back 15): unbounded queues (Low (5)); sweep's 4 gateway findings, `uri_of` (`:1328`) syncing one file under two URIs.
50. `definitions-tidy` (T6 with periodic quality, estimated medium, pushed back 10): `gd` in a float; jumps copied.
51. `plugin-host-tidy` (T6 sweep, estimated medium): 5 plugin host and plugin findings, focus left on raise (`window_requests.rb:303`).
52. `input-core-tidy` (T6 sweep, estimated medium): 9 key, grammar, and tab width findings, a key lost after invalid UTF-8 (`key_decoder.rb:212`).
53. `ui-code-tidy` (T6 sweep, estimated medium): 11 frame, presenter, and status bar findings.
54. `tools-docs-tidy` (T6 sweep, estimated medium): 14 tool, Makefile, and agent wording findings (`contributor.md:22`), with #126's agent-trim and tools_test hook-case advisories (notes 2 to 15).
55. `docs-index` (T6 folded, estimated medium, pushed back 20, split at its start): map and README drift; sweep's 3 map findings.

## Decisions

- `guard-pin-no-url` (T2 user-reported hard-rule break, #126 note 12 `checker.md:12`, the user's word) is delivered as sprint 5's second merge and leaves the queue; it takes sprint 5's one pipeline slot (agents, tools); medium: the same 10 hook lines and tools_test cases as #126 (1,263,679 total, 75.0 min).
- `brief-only-relay` (T1 pipeline, pushed back 1) moves to pool 1 as sprint 6's pipeline slot: sprint 5 holds 5 merges, at most one pipeline; sequence otherwise unchanged, the user's word.
- `untyped-gateway`, `carat-glyphs`, `architecture-review` (T2) keep their order as sprint 5's merges 3 to 5.
- `gate-object-pin` (T1 security, unrated) placed pool 3: the route #126's security review blocked on for the hooks (1 blocking at f377ec3); no confidence recorded, so not T0 yet; the sprint-5 review rates it, at Medium (8) or above it heads sprint 6 as T0.
- `hook-one-place` (T1, #126 note 19) placed pool 4: 10 copies, implement 45.3% of #126's output, 4 of 15 quality notes on trims.
- #126 note 17 folded into `spec-tests-first` (security first 0, fix round 73,089 output); note 18 into `review-demotion` (5 of 6 advisories repeated).
- #126 notes 2 to 15 (quality-advisory, appended by its package step) folded into `tools-docs-tidy`; note 12 is this delivery.
- #126 merged: rework 2, 1,263,679 total against 1.2M medium, 239,363 output against 200,000 (note 16 overrun), 75.0 min.
- `scout-focus` pushed back 3: stays T1, the highest tier below T0; passed by a security route and the hook fix.
- Security: no High or Medium at 8 or above open; #126 security review passed 0/0/0 at 54726ed.
- Pace: quality 36/85 first pass, security 81/85; sprint 4 quality 3/5 first.
- Parked: `reading-rules`, `code-index`, `harness-ruby`, `image-viewer`, the mouse.
