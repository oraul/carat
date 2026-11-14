# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 5

1. `untyped-gateway` (T2 user request, estimated medium, the user's word, sprint 5's second item after `guard-ref-pin`): the largest compile-time cost left (test-build 141 s, diagnose 172 s, CI `compile_the_tests` 137 s at #124 and 105 s at #125; runner analysis 103.7 s against carat's 43.0 s at #125) is removed with behavior unchanged; of 1,181 runner rebuilds at #124, the gateway's JSON reads (`carat/adapters/json_rpc_language_gateway.rb`) caused 210 and the language-server tests' indexing 366. Fix outline: measure first, remove the largest cause. Accepted when that cost falls, measured before and after, every stage green. Backlog: none.
2. `carat-glyphs` (T2 user now-request, estimated medium, pushed back 4, the user's word): the default `option.icons nerd` (`config/default.caratrc:27`, `carat/domain/icons.rb:11`) needs a patched font, so a stock font shows boxes for its 33 names; under `ascii` the separators and progress bar stay box drawing (`carat/adapters/frame_presenter.rb:102`, `:104`, `carat/adapters/status_bar.rb:319`). Accepted when a table-driven test finds every default glyph one cell wide outside the Private Use Areas, `nerd` stays selectable, and an `ascii` frame holds no byte above 127. Backlog: "## Window separators and the progress bar ignore option.icons ascii".
3. `architecture-review` (T2 user request, estimated medium, the user's word): "review the architecture and the holes in it... it should be expansible, easy to read and do maintenance, sometimes something became redundant there". The sprint-4 sweep's duplication and dead-code entries (`docs/backlog.md`, "## Findings of the sprint-4 review and sweep") are inputs, not its scope. Accepted when a recorded report checks `docs/architecture.md` and `docs/codebase-map.md` against the code for holes (a feature with no extension point, a rule the code breaks, a missing port or seam), redundancy (two mechanisms for one job, dead code, docs repeating or contradicting each other), and reading or maintenance costs, each with its location, why, and a fix outline, each queued; the doc is corrected where it disagrees with the code; no fix lands. Backlog: none.
4. `brief-only-relay` (T1 pipeline, user-approved, estimated medium, sprint 5's pipeline slot): the workflow relays the user's latest chat message to its agents beside the main session's brief (`.claude/workflows/deliver-change.js:945` builds the brief), so text the brief left out reaches every start. Accepted when every agent start receives only the brief or resume brief, a case showing no other user text in a start's prompt. Backlog: none.

## Pool

1. `winbar-outline` (T2 user now-request, part b of `top-rows`, estimated medium, pushed back 4): `stop` (`carat/adapters/json_rpc_language_gateway.rb:242`, called by `restart` at `:222`) keeps a symbol request in flight, so after `:LspRestart` a stale answer replaces the outline; `FramePresenter` (`frame_presenter.rb:265`) and `ArrangeView` (`carat/use_cases/arrange_view.rb:50`) each decide which windows get a winbar; a split from a scratch window has no winbar row; `symbol_outline.rb:12` says characters where the cut is in bytes. Accepted when a `test/editor_breadcrumbs.rb` row keeps the new outline after `:LspRestart` with a request in flight, a scratch split has its row, one owner decides. Backlog: "## :LspRestart lets a stale symbol answer replace the outline", "## The presenter and the arranger each decide which windows get a winbar", "## A split from a scratch window has no winbar row", "## SymbolOutline's comment says characters where the cut is in bytes".
2. `scout-focus` (T1 retrospective, estimated medium, pushed back 2): scouts 44.2% of output at #117, 31.7% and 39 of 173 calls at #124, 15.6% and 13 calls at #125 on a 2-file fix whose brief cited every line; #119's split left a pack on the undelivered part (`deliver-change.js:975`); a #117 scout went 33 calls over its cap (`:103`) with no pack. Accepted when the next three editor changes spend under 15% on scouts, a run whose brief cites every edited line none, a split's packs cover its delivered part, a capped scout leaves its pack.
3. `merged-name-guard` (T1 pipeline defect, estimated medium, pushed back 1): `/deliver` with a merged name replayed #95's run (about 120K tokens), resetting `metric.rework`. Accepted when refused unless an explicit resume, no run state written, in a case.
4. `carat-palette-b` (T2 user now-request, estimated medium): under `background terminal` lit cursor-line cells keep the terminal's foreground (`carat/domain/themes.rb:39`); #121's 2 advisories; sprint-4's 4 theme advisories (`themes.rb:474`, `:545`, `test/domain_theme.rb:297`, `color-themes/spec.md:49`). Accepted when a `test/domain_theme.rb` row holds 4.5:1 in every palette and depth. Backlog: "## The default cursor line keeps the terminal's foreground over a dark stripe".
5. `ci-scope-quoting` (T1 pipeline defect with a security Low (6), estimated small): sweep blocking `tools/ci_scope.sh:95` (a path holding a space or a glob is judged in pieces, CI skipped); `.github/workflows/ci.yml:58` runs the branch's own scope script (Low (6)); 5 ci_scope backlog entries of #125. Accepted when a code path with a space or glob runs CI and main's script decides, in cases.
6. `sprint-security` (T1 pipeline security, estimated medium, pushed back 1): a partial or not-run sprint review still grooms (Medium (7), `sprint-planning.js:121`); findings only through the skeptic (`:113`); groom drops a security entry on any ancestor (Low (6)); a forged sprint row (Low (5)); the sweep report (`:179`) and area-count slices (`periodic-review.js:65`, area 1 never read). Accepted when each refuses or records partial in a case.
7. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 3): `reRaised` demotes a blocking finding at an earlier advisory's line (#109); duplicate records (#118, #123); #122's fix round re-reviewed all (29.5%). Accepted when each holds in a case, reviews under 31,000 output in a one-round run.
8. `spec-tests-first` (T1 retrospective, estimated medium, pushed back 1): #113, #115, #118 blocked on their own untested delta spec; #121's 2 unproved scenarios; quality first 38/88. Accepted when 4 of 5 deliveries pass quality first.
9. `ux-pass` (T2 user now-request, estimated medium, pushed back 3): a three-view review of how carat feels, each finding queued.
10. `markdown-reading` (T2 user now-request, estimated large, pushed back 3): one key toggles a read-only view, no raw escape.
11. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 3): a live split preview on 10's renderer.
12. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 3): layered box text, bounded.
13. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 3): on 12's caps.
14. `finder-grep` (T5 user request, estimated medium, pushed back 5): a live grep picker.
15. `definition-tab` (T5 user request, estimated medium, pushed back 5): `<C-w>gd` in a new tab page.
16. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5): 5 workarounds; `Utf8.boundary` guards untested; advisories of #120, #123, #124; sweep's `testing.rb:66`, `test/domain_selection.rb:47`, `editor_harness.rb:190` typing findings.
17. `finder-pickers` (T5 user request, estimated medium, pushed back 5): recent-file and buffer pickers.
18. `periodic-blockers-b` (T6 periodic quality blocking, estimated medium, pushed back 7): 4 periodic blocking findings.
19. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 9): an aligned view-only table.
20. `filetype-rules` (T5 user request, estimated medium, pushed back 5): `filetype.*` lines; sweep `filetype.rb:29`.
21. `syntax-definitions` (T5 user request, estimated medium, pushed back 5): a generated Python definition.
22. `syntax-forms` (T5 user request, estimated medium, pushed back 5): Python and Java forms.
23. `syntax-embedded` (T5 user request, estimated medium, pushed back 5): fences in any language.
24. `javascript-syntax` (T5 user request, estimated medium, pushed back 5): templates, regex against division.
25. `html-syntax` (T5 user request, estimated medium, pushed back 5): tags, attributes, entities.
26. `sprint-tidy` (T1 pipeline defects, estimated medium, split at its start): plan_needed takes an unreviewed plan; a sixth merge reviewed twice; history skips a never-merged row (`run_state.sh:1372`); dictated plans 31.3% of output at #125; the package step opened the backlog to copy its form (#125 note 10). Accepted when each fails in a case, a dictated plan under 15%.
27. `ci-time-tidy` (T1 pipeline defects, estimated medium): ci-stages drops fractional steps, cuts names at 33; `Makefile:79` stale. Accepted when each fails in a case, CI under 9 min or its floor noted.
28. `open-pr-refusals` (T1 with security Lows, estimated medium, pushed back 2): refusals without a case; scanner exit 2 passes; fork heads counted (Low (5), `open_pr.sh:180`); `WAIT_STEP=0` polls forever (`:121`); the body-fix race (`deliver-change.js:1102`). Accepted when each refuses in a case.
29. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14): merger over its cap in 11 of 16 rows; `phase.merge` unlike `merged` in 12 of 75. Accepted when each has a case, wait calls 4 or fewer.
30. `run-resume` (T1 retrospective, estimated medium, pushed back 16): #115's resume reran plan and scouts (46.6%). Accepted when a resume starts at its first unfinished phase.
31. `check-runner-safety` (T1 with security Lows, estimated medium, pushed back 14): unlocked writes, a lost runner, a writable shared toolchain (Low (5), `run_state.sh:571`). Accepted when each has a case.
32. `content-gate-gaps` (T1 with security findings, estimated medium, pushed back 14): binary files skipped (Medium (7)); scanner errors read clean; `gates.sh:224` fails open on a space. Accepted when each refuses.
33. `bidi-controls` (T3 security Lows, estimated small, pushed back 10): bidi and C0 bytes reach the terminal (Low (5)).
34. `ci-hardening` (T3 with T6 folded, estimated medium, pushed back 22): actions pinned by tag (Low (5)); 6 Lows.
35. `project-config-guards` (T3 with blocking, estimated medium, pushed back 22): a cloned `.caratrc` binds a write (Low (5)).
36. `insert-copy` (T4 periodic quality, estimated small, pushed back 11): a long insert copies per key.
37. `bench-scenarios` (T4 tests, estimated small): `palette` and `lh-winbar` skipped by `tools/metrics.sh:30` and `bench/run.sh:69`; `metrics.sh:86` passes a missing figure. Accepted when every scenario runs and a missing one fails.
38. `file-access-tidy` (T4 with T6 folded, estimated medium, pushed back 25): two 64 MiB strings per run; a link race (Low (3)); sweep `list_tree.rb:67`, `:98`, `resolve_inside.rb:41`.
39. `editing-counts` (T6 with blocking, estimated medium, pushed back 10): typed count and `:undo N` uncapped; sentence motions freeze on a huge count (sweep blocking `motions.rb:488`); `buffer.rb:652` revert skips global marks.
40. `hover-tidy` (T6 folded, estimated medium, pushed back 12): stale K answers and floats.
41. `signature-tidy` (T6 with blocking, estimated medium, pushed back 11): a `(` scan by bytes.
42. `slots-tidy` (T6 with blocking and a Low, estimated medium, pushed back 11): a hidden cursor outlives its buffer.
43. `completion-tidy` (T6 folded, estimated medium, pushed back 13): 32 findings.
44. `completion-docs-tidy` (T6 with a Low, estimated medium, pushed back 13): wrong-server resolve (Low (3)).
45. `buffer-list-tidy` (T6 with a Low, estimated medium, pushed back 15): a name forges `:ls` (Low (4)).
46. `lsp-client-tidy` (T6 with Lows, estimated medium, pushed back 15): unbounded queues (Low (5)); sweep's 4 gateway findings, `uri_of` (`:1328`) syncing one file under two URIs.
47. `definitions-tidy` (T6 with periodic quality, estimated medium, pushed back 10): `gd` in a float; jumps copied.
48. `plugin-host-tidy` (T6 sweep, estimated medium): 5 plugin host and plugin findings, focus left on raise (`window_requests.rb:303`).
49. `input-core-tidy` (T6 sweep, estimated medium): 9 key, grammar, and tab width findings, a key lost after invalid UTF-8 (`key_decoder.rb:212`).
50. `ui-code-tidy` (T6 sweep, estimated medium): 11 frame, presenter, and status bar findings.
51. `tools-docs-tidy` (T6 sweep, estimated medium): 14 tool, Makefile, and agent wording findings (`contributor.md:22`).
52. `docs-index` (T6 folded, estimated medium, pushed back 20, split at its start): map and README drift; sweep's 3 map findings.

## Decisions

- `guard-ref-pin` (T0 security Medium (8), sweep `merger.md:12` at 41cf724, the user's word to start now) is delivered as sprint 5's head and leaves the queue; medium: one fix over 9 agent hooks plus a case, like #125's shell fix (835,771 total, 39.0 min).
- `untyped-gateway` (T2) is `compile-horse` renamed by the user's word: same item, place (sprint 5's second, listed first once `guard-ref-pin` leaves), and acceptance (test-build 141 s, CI compile 137 s at #124).
- `carat-glyphs`, `architecture-review` (T2) and `brief-only-relay` (T1 pipeline slot) stay in sprint 5, the user's word; no reordering.
- `scout-focus` (T1, pushed back 2) stays pool 2, accepted by the user; #125 note 9 (scouts 15.6%) folded.
- `winbar-outline` (T2, pushed back 4) pool 1: the user's word took sprint 5's places; it heads sprint 6.
- `ci-scope-quoting` (T1, small): sweep blocking `ci_scope.sh:95`, Low (6) `ci.yml:58`, #125 notes 2 to 7.
- Sprint-4 review and sweep placements carried unchanged from the waiting sprint-4 plan (74 sweep findings, quality partial 14/18).
- #125 merged: rework 1, 835,771 total, 39.0 min, within medium; notes 8, 10 to `sprint-tidy` (plan 31.3% of output).
- Groom: the sprint-4 plan (11 lines in `groom.txt`, `groomed.md`) kept as written.
- Security: Medium (8) fixed by this delivery; no other High or Medium at 8 or above open.
- Pace: quality 36/84 first pass; sprint 4 quality 3/5 first.
- Parked: `reading-rules`, `code-index`, `harness-ruby`, `image-viewer`, the mouse.
