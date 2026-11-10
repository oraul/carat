# Queue

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 34.0 held.

Items 1 to 3 are the user's bug reports after #96, 4 to 9 the UI now-request and 10 to 13 the Markdown now-request in the user's order, 14 and 16 to 20 the user's earlier order, 15 and 21 to 26 earlier requests.

1. `jump-list` (T2 user bug report, part 2a of `jump-replace-tab`, estimated medium): one editor-wide list that only `gd` fills, so Ctrl-O does nothing after `:e`, `:b`, `:bn`, the finder, the explorer, or the buffer keys; no `Ctrl-^`. Accepted when every buffer switch records the position left, each window keeps its own list (copied by a new window, 100 entries, a duplicate line dropped), `Ctrl-^`, `Ctrl-6`, and `:e #` reach the alternate file, and a Ctrl-O back to a buffer that lost its tab gives it back, a row per switch and window.
2. `jump-motions` (T2 user bug report, part 2b, estimated medium): `G`, `gg`, `/`, `?`, `n`, `N`, `*`, `#`, `%`, `(`, `)`, `{`, `}`, `H`, `M`, `L`, and `:N` add no jump. Accepted when each adds one as in Neovim with a row and a table test, and the `<C-o>` row loses "only gd adds".
3. `tab-keys` (T2 user bug report, part 3, estimated medium): `gt` and `gT` move tab pages, so with one tab page the buffer tabs the user sees are out of their reach. Accepted when `gt`, `gT`, and `{count}gt` follow the buffer tabs, `<C-PageDown>`, `<C-PageUp>`, `:tabnext` and `:tabprevious` with counts, and `g<Tab>` move tab pages, `[b`, `]b`, `[B`, `]B` move buffers, and `option.gt buffers` or `tabpages` gives Vim's back, tested with one and two tab pages.
4. `float-placement` (T2 user now-request, estimated medium): floats touch the edges and bars, only the palette is centered, plugins cannot ask for the frame; hover, signature, and peek lose 2 columns under 84 (periodic quality blocking). Accepted when every float keeps a margin, centered floats are placed at show and on resize, one frame-width rule serves all with a narrow hover row, the `FloatOptions` choice is recorded, notice titles match float titles, the folded entries are fixed, and `lh-float` and `finder` keep main's figures.
5. `menu-hints` (T2 user now-request, estimated medium): hints bottom right with `+N` groups; 5 palette names cut at 27 columns; matches not stored; the completion popup pads twice. Accepted when the hints are a centered bottom panel in even columns with named groups, palette rows align name, a dimmed column, and caret-notation keys, matches are spans in Pmenu groups, selected rows reach 4.5:1, the folded entries are fixed, and a palette scenario holds.
6. `top-rows` (T2 user now-request, estimated medium, split at its start if over four): the user never noticed the buffer tabs (shown from two files, active by bold alone, no separator or accent, shifting on the first edit); the winbar uses ` > `; a stale outline after `:LspRestart`. Accepted when tabs read at a glance (3:1 against the row and inactive tabs, never by color alone), `option.showtabline` defaults to 2, the modified mark has a fixed width, the winbar has the accent and `›` with an ASCII form, and `breadcrumbs-tidy`'s defects have rows.
7. `carat-palette` (T2 user now-request, estimated large): all 4 palettes are other editors'; cursor-line text 3.90 to 4.43:1. Accepted when `carat-dark` and `carat-light` with a gem accent are the default, others kept, every palette passes 4.5:1 text and 3:1 decorations at each depth, and `theme-tidy`'s 17 advisories are fixed or owned; split at its start.
8. `carat-glyphs` (T2 user now-request, estimated medium): the default `option.icons nerd` needs a patched font; separators mix ASCII and box drawing. Accepted when a carat set of characters every monospace font has is the default, `ascii` is improved, `nerd` gives a one-time `file:line` deprecation notice, every glyph is one cell, with frame snapshots per set.
9. `ux-pass` (T2 user now-request, estimated medium): no review of how carat feels. Accepted when a three-view review of first use, empty and loading states, failed keys, messages, floats, and key-to-answer time is recorded, each finding queued or a backlog entry with a reproduction.
10. `markdown-reading` (T2 user now-request, split from `markdown-preview`, estimated large): no reading view for the documents the user reads. Accepted when one key toggles a read-only view with a readable measure, headings not by color alone, lists, aligned tables, links, heading jumps and an outline, fences highlighted or plain, size and nesting caps, no raw escape, frame snapshots, and figures held when closed.
11. `markdown-preview` plugin (T2 user now-request, estimated medium): a split preview with live update and scroll sync on 10's renderer, frame snapshots, figures held when closed.
12. `mermaid-flowchart` (T2 user now-request, estimated large): Mermaid shows as source. Accepted when `flowchart` and `graph` draw as box text in layers with labeled, dotted, and arrowed edges, subgraphs as titled frames, the user's roadmap fixture drawn, labels stripped of controls, parse and layout bounded, wide ones scrolled, and others shown as source with a note.
13. `mermaid-sequence` (T2 user now-request, estimated medium): `sequenceDiagram` participants, lifelines, messages, and notes on 12's caps, a row per form.
14. `finder-grep` (T5 user request, estimated medium, pushed back 2): no content search. Accepted when a live grep picker filters, results are capped and stripped, Enter opens at the line, with rows.
15. `definition-tab` (T5 user request, estimated medium, pushed back 2): no `<C-w>gd`. Accepted when it opens `gd`'s targets in a new tab page, the jump list keeps the position left, and no target changes nothing, with rows.
16. `spinel-workarounds` (T2 user request, estimated medium, pushed back 2): 5 Spinel workarounds. Accepted when each fixed one is dropped with a test, and allocations, rounds, and analysis time hold.
17. `finder-pickers` (T5 user request, estimated medium, pushed back 2): no recent-file or buffer picker. Accepted when both filter and open with 5's spans, each with a row.
18. `periodic-blockers-b` (T6 periodic quality blocking, estimated medium, pushed back 4): 7 blocking findings, one still open at 6a0db20. Accepted when each is fixed with a row or owned; split if over four.
19. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 6): an aligned view-only table, sticky header, sort, raw toggle, RFC 4180, caps.
20. `backlog-compaction` (T1 efficiency, estimated medium, pushed back 3): `docs/backlog.md` 405,809 bytes (+8,244); 34 entries name gone items, 3 duplicate pairs. Accepted when each entry has one live owner, a docs-lint budget and owner check fail in a case, and growth averages under 5 KB a merge over 5 runs.
21. `filetype-rules` (T5 user request, estimated medium, pushed back 2): `filetype.extension`, `.name`, `.shebang` lines, a project's capped at `file:line`, rows.
22. `syntax-definitions` (T5 user request, estimated medium, pushed back 2): a Python definition in the `.caratrc` format generated into committed Ruby, a sync test, nothing read at run time.
23. `syntax-forms` (T5 user request, estimated medium, pushed back 2): Python and Java forms with existing groups, a row each.
24. `syntax-embedded` (T5 user request, estimated medium, pushed back 2): spans as another filetype, fences in any language, rows.
25. `javascript-syntax` (T5 user request, estimated medium, pushed back 2): `js`, `mjs`, `cjs`, templates, regex against division, rows.
26. `html-syntax` (T5 user request, estimated medium, pushed back 2): tags, attributes, entities, script through 24, rows.
27. `merge-gate-tidy` (T1 pipeline defect, estimated medium, pushed back 9): a live body gained a session footer (12 of 55); the merger over its cap in 9 of 13 rows. Accepted when each has a case and a live body unlike the gated one refuses the merge.
28. `phase-shares` (T1 retrospective, estimated medium, pushed back 11): plan plus scout 31.7% to 48.4%, 38.2% in #97. Accepted when a one-area change is under 20% over three runs.
29. `run-resume` (T1 retrospective, estimated medium, pushed back 11): a resume reran plan and scouts (24.7% of #89). Accepted when it starts at check and rework never passes 3.
30. `check-skip` (T1 retrospective, estimated medium, pushed back 11): 621 of 627 s of build on docs-only; CI 13.0 and 17.0 min. Accepted when docs-only checks take under 60 s and CI under 10 min in 3 runs.
31. `check-runner-safety` (T1 with security Lows, estimated medium, pushed back 9): unlocked writes, a lost runner (Low (4)), shared toolchain (Low (5)). Accepted when each has a case.
32. `content-gate-gaps` (T1 with security findings, estimated medium, pushed back 9): the gate skips a binary file (Medium (7)) and 5 Lows. Accepted when it refuses each in a case.
33. `backup-records` (T1 retrospective, estimated small, pushed back 9): the backup failed in every attempt of #91 to #97. Accepted when 3 runs record none and a resume finds its commits.
34. `review-scope` (T1 retrospective, estimated medium, pushed back 12): fix rounds re-raise advisories as blocking; 2 of #97's 4 blockers were script-checkable docs (24.3% of its output); quality first 23 of 60. Accepted when no round comes from an earlier advisory over 5 runs and a gate fails on an option or bench scenario with no docs row.
35. `bidi-controls` (T3 security Lows, estimated small, pushed back 5): bidi and C0 bytes reach the terminal (Low (5)). Accepted with a row per source.
36. `ci-hardening` (T3 with T6 folded, estimated medium, pushed back 17): 4 Lows (6) to (4). Accepted when a case covers each and actions are pinned.
37. `project-config-guards` (T3 with blocking, estimated medium, pushed back 17): a cloned `.caratrc` binds a write (Low (5)). Accepted with a row each.
38. `insert-copy` (T4 periodic quality, estimated small, pushed back 6): a long insert copies per key. Accepted when bytes per key stay flat.
39. `file-access-tidy` (T4 with T6 folded, estimated medium, pushed back 20): two 64 MiB strings per test run. Accepted when none allocates it and `open-ruby` stays 24.0.
40. `editing-counts` (T6 with blocking, estimated medium, pushed back 5): a long count before `p` freezes; `ci(` on `()`; sentence scans. Accepted with rows for each.
41. `hover-tidy` (T6 folded, estimated medium, pushed back 7): K shows an older answer (blocking). Accepted with a row per defect.
42. `signature-tidy` (T6 with blocking, estimated medium, pushed back 6): a `(` scan by bytes. Accepted with a row per defect.
43. `slots-tidy` (T6 with blocking and a Low, estimated medium, pushed back 6): a hidden cursor outlives its buffer. Accepted with a row per defect.
44. `completion-tidy` (T6 folded, estimated medium, pushed back 8): 32 findings. Accepted when the gateway defects have rows.
45. `completion-docs-tidy` (T6 with a Low, estimated medium, pushed back 8): wrong-server resolve (Low (3)); the docs float under the popup at the edge. Accepted with a case each.
46. `buffer-list-tidy` (T6 with a Low, estimated medium, pushed back 10): a name forges `:ls` (Low (4)). Accepted with a row each.
47. `lsp-client-tidy` (T6 with Lows, estimated medium, pushed back 10): unbounded queues (Low (5)); a 1373-line gateway. Accepted when memory stays capped.
48. `definitions-tidy` (T6 with periodic quality, estimated medium, pushed back 5): `gd` in a float; the peek unhighlighted. Accepted with a row per defect.
49. `docs-index` (T6 folded, estimated medium, pushed back 15): 21 pull requests missing from the map; the architecture 3 bytes under budget. Accepted when a check fails on a gap.
50. `guard-lows` (T6 with a Medium (4), estimated medium, pushed back 19): agent files rewritable. Accepted with a refusal case each.
51. `substitute-tidy` (T6 with a Low, estimated medium, pushed back 17): many `&` (Low (6)). Accepted with a row each.
52. `search-tidy` (T6 folded, estimated medium, pushed back 20): 1.5 s per incremental key. Accepted when a preview key stays in budget.
53. `bars-tidy` (T6 folded, estimated medium, pushed back 9): about 17 status bar entries. Accepted when each is fixed or owned.
54. `run-budgets-tidy` (T6 folded, estimated medium, pushed back 9): 42 advisories; a missing strict metric passes. Accepted when it fails in a case.
55. `discoverability-tidy` (T6 with a Low, estimated small, pushed back 6): Enter under a plugin prompt (Low (3)). Accepted with a row each.
56. `messages-tidy` (T6 with periodic quality, estimated medium, pushed back 5): `:messages` drops E37 and E162. Accepted with rows.
57. Backlog batches (T6 folded by domain, estimated small each, pushed back 26): copies, config checks, RBS pins, comment wraps, dead code, generators, test hygiene, ideas.

## Decisions

- `jump-replace-tab` (T2 user bug report after #96, delivered now): Part 1 only, estimated medium for 2 fixes in `gd-ghost-tab`'s area (1,959,229 total, 82 min, medium, overran); it replaces `gd-ghost-tab` in the user's mind.
- Part 2 split into 1 and 2 (4 fixes, over the limit), Part 3 is 3; T2 user bug reports right after it, ahead of the UI by the user's word.
- UI items 4 to 9 in the user's order A, B, C, D, F, E; C now owns the unnoticed tabs and `option.showtabline 2`, F is the user's new item.
- Markdown (T2 now-request) after the UI: `markdown-preview` split into 10 to 13 as large as one; state, class, gantt, and pie diagrams wait for 12.
- #97 periodic quality (partial 14/18, 1 blocking, 32 advisory): blocking frame width into 4; folds into 4, 5, 7, 8, 20, 34, 36, 40, 45, 47 to 49, 52, 54, 57.
- #97 advisories in `docs/backlog.md` without an owner: centering, finder sizes, double fetch into 4; the bench list into 54.
- #97 retro: notes 17 and 18 into 34, backup into 33, merger 14 calls over 12 into 27; overrun 2,246,983 total against medium.
- Security: #97 and periodic security at 6a0db20 pass, 0 findings; no High or Medium at 8 or above.
- 18 stays behind the T2 items by goal 1 though its blocker is open at 6a0db20; 14 to 57 pushed back 1 by goal 1.
- Features first: 1 to 17 are user reports or features; no non-feature change is due.
- Allocation figures from #97: `lh` 26.0, `j` 27.0, `insert` 34.0, `open-ruby` 24.0. Standing: indent guides core, breadcrumbs default kept.
- Parked: `image-viewer`, the mouse, a CSV chart; a carat font (optional, own repository, SIL licensed under a new name, `option.icons carat-font`); SVG icons (own rasterizer, kitty or sixel, falling back to 8).
