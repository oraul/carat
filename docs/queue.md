# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 34.0 held.

## Sprint 3

1. `top-rows` (T2 user now-request, estimated large, pushed back 3, split at its start if over four): the user never noticed the buffer tabs (`carat/adapters/tab_bar.rb`); the winbar joins symbols with `SEPARATOR = " > "` (`carat/adapters/winbar.rb:18`); `stop` keeps a symbol request in flight, so after `:LspRestart` a stale answer replaces the outline (`carat/adapters/json_rpc_language_gateway.rb:227`); a split from a scratch window has no winbar row. Fix outline: tabs and winbar restyled, the outline request forgotten on stop. Accepted when tabs read at a glance at 3:1 and never by color alone, the modified mark has a fixed width, the winbar has the accent and `›` with an ASCII form under `option.icons ascii`, and an `test/editor_breadcrumbs.rb` row keeps the new outline after `:LspRestart` with a request in flight. Backlog: "## :LspRestart lets a stale symbol answer replace the outline", "## The presenter and the arranger each decide which windows get a winbar", "## A split from a scratch window has no winbar row", "## The tab bar copies the status bar's digit fit", "## SymbolOutline's comment says characters where the cut is in bytes".
2. `carat-palette` (T2 user now-request, estimated large, pushed back 3, split at its start): the 4 palettes of `NAMES` (`carat/domain/themes.rb:25`) are other editors', `option.theme one_dark` the default (`config/default.caratrc:55`); cursor-line text at 3.90 to 4.43:1 (`CURSOR_LINE`, `carat/domain/themes.rb:39`); under `background terminal` lit cells keep the terminal's foreground over a dark stripe. Fix outline: carat's own dark and light palettes with a gem accent. Accepted when `carat-dark` and `carat-light` exist, `carat-dark` is the default, and every palette passes 4.5:1 text and 3:1 decorations at each color depth in `test/domain_theme.rb`, the cursor line under `background terminal` included. Backlog: "## Text on the cursor line falls below 4.5:1 in every palette", "## The default cursor line keeps the terminal's foreground over a dark stripe", "## A 16-color background index is named like a group id in the theme build", "## The UI highlight group count is stale", "## The theme test's group comment is out of date".

## Pool

1. `pr-edit-path` (T1 pipeline security Medium (7), estimated medium, pushed back 2, sprint 4's pipeline item): body mode (`.claude/agents/contributor.md:59`, `:51`) edits the pull request from the session, while `tools/open_pr.sh:2` and `.github/workflows/open-pr.yml:4` say a session's API edit gets a footer naming the session; the update tool stays granted (`.claude/agents/contributor.md:4`) with no guard hook (sprint-2 sweep Low (6)); `README.md:196` disagrees; a run that pushed but recorded no number reruns the package step (`.claude/workflows/deliver-change.js:981`) into the refused second push; `contributor.md` holds 8,148 of 8,192 bytes. Accepted when the contributor holds no pull request write tool and a case refuses one, a title or body fix reaches the pull request without one, one rule stands in all four texts, a case resumes past the push with no number without committing or pushing, and `contributor.md` is under 7,000 bytes. Backlog: "## delivery-speed quality advisory at .claude/agents/contributor.md:59", "## pr-on-push quality advisory at tools/open_pr.sh:2", "## pr-on-push quality advisory at .claude/workflows/deliver-change.js:982", "### Contributor agent file has no headroom (`pr-on-push` retrospective)", "## The contributor's pull request tools have no guard hook".
2. `sprint-security` (T1 pipeline security, estimated medium): a partial or not-run sprint review still plans and grooms (Medium (7), `sprint-planning.js:121`); findings reach the run state only through the skeptic (Medium (7), `:113`); groom drops a security entry on any ancestor (Low (6), `run_state.sh:1497`); a forged sprint row settles the gate (sprint-2 Low (5), `tools/gates.sh:117`). Accepted when each refuses or records partial in a case.
3. `review-demotion` (T1 pipeline defect, estimated medium, pushed back 2): `reRaised` demotes a blocking quality finding at an earlier advisory's file:line (#104 merged one unfixed); 2 of 4 blocking at #109 a round late. Accepted when a finding blocking before or new in the fix diff stays blocking in a case.
4. `spec-tests-first` (T1 retrospective, estimated medium): #113 blocked on 3 and #115 on 1 untested behavior of their own delta spec; #116 blocked on a caller left on a helper's old result (`text_room` cols - 4 to cols - 6, guard at `show_key_hints.rb:125`); quality first pass 30/75, 4 of the last 10. Accepted when over five deliveries no blocking finding names the change's own requirement or a caller of a function whose result it altered, and quality passes first in 4.
5. `carat-glyphs` (T2 user now-request, estimated medium, pushed back 3): `option.icons nerd` needs a patched font; separators mix ASCII and box drawing. Accepted when a set every monospace font has is the default, every glyph one cell.
6. `ux-pass` (T2 user now-request, estimated medium, pushed back 3): no review of how carat feels. Accepted when a three-view review is recorded, each finding queued.
7. `markdown-reading` (T2 user now-request, estimated large, pushed back 3): no reading view. Accepted when one key toggles a read-only view, no raw escape.
8. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 3): a split preview with live update and scroll sync on 7's renderer.
9. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 3): `flowchart` and `graph` as layered box text, bounded.
10. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 3): `sequenceDiagram` on 9's caps.
11. `finder-grep` (T5 user request, estimated medium, pushed back 5): a live grep picker.
12. `definition-tab` (T5 user request, estimated medium, pushed back 5): `<C-w>gd` opens `gd`'s targets in a new tab page.
13. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5): 5 Spinel workarounds; each fixed one dropped with a test.
14. `finder-pickers` (T5 user request, estimated medium, pushed back 5): recent-file and buffer pickers.
15. `periodic-blockers-b` (T6 periodic quality blocking, estimated medium, pushed back 7): 4 periodic blocking findings.
16. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 9): an aligned view-only table.
17. `filetype-rules` (T5 user request, estimated medium, pushed back 5): `filetype.extension`, `.name`, `.shebang` lines.
18. `syntax-definitions` (T5 user request, estimated medium, pushed back 5): a Python definition generated into committed Ruby.
19. `syntax-forms` (T5 user request, estimated medium, pushed back 5): Python and Java forms.
20. `syntax-embedded` (T5 user request, estimated medium, pushed back 5): fences in any language.
21. `javascript-syntax` (T5 user request, estimated medium, pushed back 5): `js`, `mjs`, `cjs`, templates, regex against division.
22. `html-syntax` (T5 user request, estimated medium, pushed back 5): tags, attributes, entities, script through 20.
23. `sprint-tidy` (T1 pipeline defects, estimated medium, split at its start): plan_needed takes an unreviewed plan; a sixth merge reviewed twice; quality gets no continuation; history and groom skip on a row of a branch that never merges (sprint-2 sweep, `tools/run_state.sh:1372`). Accepted when each fails in a case.
24. `ci-time-tidy` (T1 pipeline defects, estimated medium): ci-stages may drop every step on fractional seconds, cuts names at 33, is queued on every CI return. Accepted when each fails in a case and three runs record the stages.
25. `scout-focus` (T1 retrospective, estimated medium): scouts 57,857 of 130,948 output tokens (44.2%) and 60 of 158 calls at #117, a medium one-area change, the sixth editor run at 23% or more (#113 23.1%, #114 27.7%, #115 33.1%, #116 28.9%); one of #117's 2 scout starts made 33 calls over its cap of 30 and left no pack; 3 #116 packs restated `FloatWindow.text_room` and none named the caller it blocked on. Accepted when the next three editor changes spend under 15% of output tokens and calls on scouts, a capped scout start still leaves its pack in `tmp/scout/`, and no blocking finding lands on a caller of a function the change modified.
26. `open-pr-refusals` (T1 with #108's periodic blocking and a Low, estimated medium, pushed back 2): the opener's refusals have no case; a scanner exit 2 passes any title. Accepted when each refuses in a case.
27. `merge-gate-integrity` (T1 pipeline defect, estimated medium, pushed back 14): merger over its cap in 11 of 16 rows; `phase.merge` unlike `merged` in 12 of 75 run states. Accepted when each has a case.
28. `run-resume` (T1 retrospective, estimated medium, pushed back 16, split at its start if over four): #115's resume past a recorded implement reran plan and scouts (87,970 of 188,801 output, 46.6%). Accepted when a resume starts at its first unfinished phase and records no finding twice.
29. `check-runner-safety` (T1 with security Lows, estimated medium, pushed back 14): unlocked writes, a lost runner, shared toolchain, a planted toolchain config. Accepted when each has a case.
30. `content-gate-gaps` (T1 with security findings, estimated medium, pushed back 14): binary files skipped (Medium (7)); unquoted secrets pass; scanner errors read clean. Accepted when each refuses in a case.
31. `bidi-controls` (T3 security Lows, estimated small, pushed back 10): bidi and C0 bytes reach the terminal (Low (5)).
32. `ci-hardening` (T3 with T6 folded, estimated medium, pushed back 22): actions pinned by tag beside `PR_TOKEN` (Low (5), sprint-2 sweep); 6 Lows. Accepted when actions are pinned and a case covers each.
33. `project-config-guards` (T3 with blocking, estimated medium, pushed back 22): a cloned `.caratrc` binds a write (Low (5)).
34. `insert-copy` (T4 periodic quality, estimated small, pushed back 11): a long insert copies per key.
35. `file-access-tidy` (T4 with T6 folded, estimated medium, pushed back 25): two 64 MiB strings per test run; a link race on create (Low (3)).
36. `editing-counts` (T6 with blocking, estimated medium, pushed back 10): a typed count uncapped; `:undo N` uncapped (sprint-2 sweep); Tab with expandtab by character column (`carat/use_cases/insert_tab.rb:22`).
37. `hover-tidy` (T6 folded, estimated medium, pushed back 12): K shows an older answer; a timed-out key leaves floats stale.
38. `signature-tidy` (T6 with blocking, estimated medium, pushed back 11): a `(` scan by bytes.
39. `slots-tidy` (T6 with blocking and a Low, estimated medium, pushed back 11): a hidden cursor outlives its buffer.
40. `completion-tidy` (T6 folded, estimated medium, pushed back 13): 32 findings.
41. `completion-docs-tidy` (T6 with a Low, estimated medium, pushed back 13): wrong-server resolve (Low (3)).
42. `buffer-list-tidy` (T6 with a Low, estimated medium, pushed back 15): a name forges `:ls` (Low (4)).
43. `lsp-client-tidy` (T6 with Lows, estimated medium, pushed back 15): unbounded queues (Low (5)); a 1373-line gateway.
44. `definitions-tidy` (T6 with periodic quality, estimated medium, pushed back 10): `gd` in a float; `:tabnew` from a float copies its jumps; a plugin's tab switch skips `TabList#visit`, so `g<Tab>` goes wrong (sprint-2 review, `carat/use_cases/plugins/window_requests.rb:132`); #116's `float_frame` advisories (`window_requests.rb:260`, `plugin_link.rb:276`).
45. `docs-index` (T6 folded, estimated medium, pushed back 20, split at its start): 21 pull requests missing from the map; drift at 8b9bf6a (map, README `%` and `<C-^>`). Accepted when a check fails on each gap.
46. `guard-lows` (T6 with Mediums (4) to (6), estimated medium, pushed back 24): OpenSpec unpinned beside push credentials (Medium (4), `tools/spec_validate.sh:17`); agent files rewritable (Medium (5)); submodule config runs a command (Medium (6)).
47. `substitute-tidy` (T6 with a Low, estimated medium, pushed back 22): many `&` (Low (6)).
48. `search-tidy` (T6 folded, estimated medium, pushed back 25): 1.5 s per incremental key.
49. `bars-tidy` (T6 folded, estimated medium, pushed back 14): about 17 status bar entries.
50. `run-budgets-tidy` (T6 folded, estimated medium, pushed back 14): 42 advisories.
51. `discoverability-tidy` (T6 with a Low and 7 advisories, estimated medium, pushed back 11): Enter under a plugin prompt (Low (3)); #116's guard advisory at `show_key_hints.rb:125` if it stands; #117's 6: an empty literal filled by a callee (`show_key_hints.rb:112`), a plugin prefix read as `plugin` (`:131`), stale comments (`hide_key_hints.rb:7`, `float_window.rb:16`), a doubled `showing?` guard (`handle_key.rb:145`), `KeymapNode#binding_count` with no caller (`keymap_node.rb:76`).
52. `messages-tidy` (T6 with periodic quality, estimated medium, pushed back 10): `:messages` drops E37 and E162.
53. `open-pr-tidy` (T6 folded, estimated medium, pushed back 2): read-back by branch name, branch types in three places.
54. Backlog batches (T6 folded by domain, estimated small each, pushed back 31): one change per domain.

## Decisions

- `palette-rows` (T2 user now-request, part b of `menu-hints`) delivered now as sprint 3's third merge, estimated medium: 3 fixes and 2 headings, under the about-four split line; comparable `menu-hints` 878,933 total and 51.0 min, `float-placement` 1,176,745 and 118.0; its locations hold at 84467c6 (`follow_palette.rb:30`, `:151`, `open_completion_popup.rb:54`).
- `top-rows` and `carat-palette` (T2) keep sprint 3's last two slots; sprint 3 holds 5 features and 0 pipeline items.
- `pr-edit-path` (T1 Medium (7), confidence under 8, not T0) stays pool 1 as sprint 4's pipeline item.
- #117 note 8 (scouts 44.2% of output, 38.0% of calls) and note 7 (scout 33 calls over its cap of 30) update `scout-focus` (T1), in place: sprint 3 is full and sprint 4's pipeline slot is `pr-edit-path`'s.
- #117 note 9 dropped: closing own-line advisories in the run contradicts the goals' rule that advisories are recorded and never chased mid-run (the user's decision of 2026-11-11).
- #117's advisories 1 to 6 (quality 0 blocking, 6 advisory, appended at its package step) fold into `discoverability-tidy` (T6), now 8 discovery findings, estimated medium; nothing new to the backlog.
- Pace: #117 51.0 wall min at 878,933 total under its medium budget, first pass on every gate; sprint 3 at 169.0 min over 2 merges (84.5 each); this package step adds its history row once.
- Security: #117's review passed, 0 findings; no High or Medium at confidence 8 or above open; sprint-1's Mediums (7) stay with `pr-edit-path` and `sprint-security`, the sweep's Medium (4) with `guard-lows`.
- Parked: `reading-rules`, `code-index`, `harness-ruby`, `image-viewer`, the mouse. Figures from #117: `lh` 26.0, `j` 27.0, `insert` 34.0 held.
