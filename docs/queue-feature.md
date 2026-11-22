# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 27

Drained: buffer-picker, folded-row, float-painter delivered, the 3 features of the sprint; /sprint draws the next.

## Pool

1. `ui-groups` (T2 user request, estimated small, pushed back 6, reason: the waves): PANEL_DIM, the message row's indicators; `picker-speed` (T2, medium, pushed back 2).
2. `finder-switch` (T2 user request, estimated medium, pushed back 2, reason: the basics); `finder-rows` (T2, large, pushed back 3, reason: the user's order of 2026-11-21, critical e carat/plugins/finder/plugin.rb).
3. Facet waves 3 to 5 (T2 user request, estimated medium each): `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`, `separator-styles`, `one-accent`, `glyph-audit`; `plugin-ui-tokens` ("### style_float checks a span's start column only from below (sprint-23 review security Low (3), disputed)"), `finder-refined`, `key-hints-dock`, `explorer-rows`; `start-gem`, `diagnostic-text`, `explorer-git`.
4. `finder-preview-gutter` (T2, estimated small, pushed back 1); `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops` (medium each, pushed back 1); `search-count` (medium, pushed back 5).
5. `background-theme` (T2 user request, estimated medium, pushed back 2, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries, sweep note 51 (`ansi_terminal.rb:83`).
6. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 2, critical a carat/plugin_api.rb): its 4 headings at 24e3738, less those backlog Sprint 27 item 3 lists.
7. `vim-folds-d` (T2, estimated medium, pushed back 1); `markdown-reading-e` (T2, medium, pushed back 5, reason: no location).
8. Async (T2 user request, estimated medium each, pushed back 1): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` (2 headings at 24e3738), `program-jobs`; the debugger: `socket-probe`, `debug-keys` (small), `debug-breakpoints`, `debug-channel`, `debug-session` (large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
9. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track); `git-panel` (T2, large, pushed back 5); `claude-bridge`, `claude-workflow` (T2 ideas, large); `lint-panel` (T2, large, pushed back 2).
10. Containers (T2 user request, estimated medium each, after the Facet waves and finder work): `dockerfile-support` (small), `containers-panel` (`<leader>C`), `containers-logs` (after plugin-tasks), the rest as the notes of 2026-11-21 slice them.
11. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, medium each).
12. `theme-tuning`, `semantic-highlight` (T5 roadmap, estimated medium, large); `plugin-protocol-a`, `formatting` (T5, medium, pushed back 2); `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, medium each).
13. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track); `csv-viewer` (T5, large, pushed back 10).
14. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, small).

## Decisions

- Security first (T0): none; periodic security at 3370625 high=0 medium=0 low=3; sprint-26 review High 0, Medium 0; no `review.periodic` in the 3 pending runs (folded-row, merge-gate-lows, review-in-openspec).
- Delivered (T2): float-painter, council (4), the third Sprint 27 feature after buffer-picker and folded-row, removed; the sprint's feature share drained (0 of 3 waiting), the pool unchanged, none pushed back.
- Size (T2): large, critical e carat/adapters/frame_presenter.rb; the extraction it repeats ran over medium (status-winbar-tabs 1,226,138 in 62 min, status-winbar-tabs-b 2,192,549 in 143); the last two feature runs under budget (folded-row 1,040,616 large, buffer-picker 1,069,800 large), so no size up.
- No split (T2): one collaborator for the float layer, `build_float_key` `:461` to `clamp` `:760` at 3411c26 (about 300 of 1474 lines, 60 methods), its wiring and map entry; one acceptance (every frame snapshot unchanged), not 3 independently testable parts.
- Lines (T2): the brief's `:649`, `:669`, `:712` are `:653`, `:673`, `:716` at 3411c26 (folded-row added 4); calls `:266`, `:267`, `:314`, `:315`; `paint_edge` `:567` serves notices `:551` and floats `:739`.
- Merge gate rules (T1): the outline edits no `tools/rules.sh` pattern.
- Notes (T1): folded-row retro 2 to 4, with head-form notes 1, 5 as note 4's evidence, go to backlog.md, merged into backlog Pool 14 (`areas-in-plan`, `scout-prune`, `merge-wait-bound`, `head-drop`); this lane leaves `docs/queue-backlog.md` alone; merge-gate-lows and review-in-openspec notes were placed by earlier plans.
