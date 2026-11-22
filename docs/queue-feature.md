# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 28

Drained: ui-groups, picker-speed, finder-switch delivered, the 3 features of the sprint; /sprint draws the next.

## Pool

1. `finder-rows` (T2 user request, estimated large, pushed back 4, reason: the user's order of 2026-11-21, critical e carat/plugins/finder/plugin.rb); `recent-files-persist` (T2, small): "### The recent files are kept for one run only".
2. Facet waves 3 to 5 (T2 user request, estimated medium each): `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish` ("### The float key's layout is read in two classes at carat/adapters/frame_presenter.rb", sprint-27 note 6), `separator-styles`, `one-accent`, `glyph-audit`; `plugin-ui-tokens` ("### style_float checks a span's start column only from below (sprint-23 review security Low (3), disputed)"), `finder-refined`, `key-hints-dock`, `explorer-rows`; `start-gem`, `diagnostic-text`, `explorer-git`.
3. `finder-preview-gutter` (T2, estimated small, pushed back 1); `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops` (medium each, pushed back 1); `search-count` (medium, pushed back 5).
4. `background-theme` (T2 user request, estimated medium, pushed back 2, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries, sweep note 51 (`ansi_terminal.rb:83`).
5. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 2, critical a carat/plugin_api.rb): its 4 headings at 24e3738, less those backlog Pool 1 lists.
6. `vim-folds-d` (T2, estimated medium, pushed back 1): "### The closed fold's text is not the design's chevron and count", "### The fold label's fill is not ASCII under option.icons ascii and NO_COLOR"; `markdown-reading-e` (T2, medium, pushed back 5, reason: no location).
7. Async (T2 user request, estimated medium each, pushed back 1): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` (2 headings at 24e3738), `program-jobs`; debugger: `socket-probe`, `debug-keys` (small), `debug-breakpoints`, `debug-channel`, `debug-session` (large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
8. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track); `git-panel`, `lint-panel` (T2, large, pushed back 5, 2); `claude-bridge`, `claude-workflow` (T2 ideas, large).
9. Containers (T2 user request, estimated medium each, after the Facet waves and finder work): `dockerfile-support` (small), `containers-panel` (`<leader>C`), `containers-logs` (after plugin-tasks), the rest as the notes of 2026-11-21 slice them.
10. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, medium each).
11. `theme-tuning`, `semantic-highlight` (T5 roadmap, estimated medium, large); `plugin-protocol-a`, `formatting` (T5, medium, pushed back 2); `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, medium each).
12. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track); `csv-viewer` (T5, large, pushed back 10).
13. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, small).

## Decisions

- Security first (T0): none; the 3 pending runs (picker-speed, review-in-openspec, sprint-close-lows) hold no `review.periodic`; sprint-27 review High 0, Medium 0.
- Delivery (T2): finder-switch, Sprint 28 item after picker-speed (#301), user request, pushed back 2, removed; Sprint 28 drained, 3 features; not critical: the finder plugin, its bindings, `docs/actions.md`, tests, no API change, so no `carat/plugin_api.rb` edit (rule d).
- Size (T2): medium; medium feature rows ui-groups 980,589 in 82.1 min, hidden-option 1,099,813 in 68.0, picker-speed 896,376 in 72.0; the last two under the 1.2M budget, no size up.
- Split (T2): none; 2 testable parts (`<C-g>` switch, `<leader>fw`) in 1 map area (finder plugin).
- Findings (T1): picker-speed retro 2, 3, 4, review-in-openspec overruns 8 (check 653,549 output against 416,666), 12 (contributor 1,372,173 against 1.2M), sprint-close-lows overrun 4 (sprint-27-records 44.3 min against 25) are backlog-lane pipeline items this delivery may not edit: to backlog.md.
