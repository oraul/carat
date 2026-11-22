# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 26

## Pool

1. `buffer-picker` (T2 user request, council (2), (3), estimated large, pushed back 1, reason: set-options' split parts first, critical e carat/plugins/finder/plugin.rb): `<leader>fb` buffers, `<leader>fr` recent files (bounded), `<leader>fR` resumes the last search; a test per key, frame rows in both themes and ascii, `docs/actions.md` rows. Backlog: none.
2. `folded-row` (T2 user request, Facet wave 2, estimated large, pushed back 2, reason: the basics first, critical e carat/adapters/frame_presenter.rb): the fold row (`frame_presenter.rb:799` at 7156f43) paints Normal, not `docs/design.md`'s Folded; frame rows in both themes, ascii, 16 colors, NO_COLOR. Backlog: none.
3. `float-painter` (T2 user request, estimated medium); `ui-groups` (T2, small, pushed back 5, reason: the waves): PANEL_DIM, the message row's indicators; `picker-speed` (T2, medium, pushed back 1).
4. `finder-switch` (T2 user request, estimated medium, pushed back 2, reason: the basics); `finder-rows` (T2, large, pushed back 3, reason: the user's order of 2026-11-21, critical e carat/plugins/finder/plugin.rb).
5. Facet waves 3 to 5 (T2 user request, estimated medium each): `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`, `separator-styles`, `one-accent`, `glyph-audit`; `plugin-ui-tokens` ("### style_float checks a span's start column only from below (sprint-23 review security Low (3), disputed)"), `finder-refined`, `key-hints-dock`, `explorer-rows`; `start-gem`, `diagnostic-text`, `explorer-git`.
6. `finder-preview-gutter` (T2, estimated small, pushed back 1); `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops` (medium each, pushed back 1); `search-count` (medium, pushed back 5).
7. `background-theme` (T2 user request, estimated medium, pushed back 2, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries.
8. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 2, critical a carat/plugin_api.rb): its 4 headings as listed at 24e3738.
9. `vim-folds-d` (T2, estimated medium, pushed back 1); `markdown-reading-e` (T2, medium, pushed back 5, reason: no location).
10. Async (T2 user request, estimated medium each, pushed back 1): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` (2 headings at 24e3738), `program-jobs`; then the debugger (council of 2026-11-21): `socket-probe` (small), `debug-keys` (small), `debug-breakpoints`, `debug-channel`, `debug-session` (large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
11. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track); `git-panel` (T2, large, pushed back 5); `claude-bridge`, `claude-workflow` (T2 ideas, large); `lint-panel` (T2, large, pushed back 2).
12. Containers (T2 user request, estimated medium each, after the Facet waves and finder work): `dockerfile-support` (estimated small), `containers-panel` (medium, the engine port inside its directory, `<leader>C`), `containers-logs` (medium, after plugin-tasks), the rest as the notes of 2026-11-21 slice them.
13. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, medium each).
14. `theme-tuning`, `semantic-highlight` (T5 roadmap, estimated medium, large); `plugin-protocol-a`, `formatting` (T5, medium, pushed back 2); `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, medium each).
15. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track); `csv-viewer` (T5, large, pushed back 10).
16. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, small).

## Decisions

- Security first (T0): none; 0 review.periodic in 3 pending runs (hidden-option, review-in-openspec, spinel-catchup-b); sprint-25 review High 0, Medium 0 at 8+.
- Delivered (T2 user request, council (2)): colorscheme-command, Sprint 26 item 1, removed; Sprint 26 drained, 0 items, waiting for /sprint: set-options (6a24eae2bb70), hidden-option (b6c2b44cfe1e), colorscheme-command: 3 features.
- Size (T2): large, critical e; comparable large rows set-options 1,285,703 in 86 min, cmdline-completion 1,248,692 in 94, border-vocabulary 1,499,363 in 108, all under 2.5M; not medium: 4 areas against hidden-option's 2 at 1,099,813 of 1.2M; last two under budget (set-options, hidden-option), no size up.
- Split (T2): none; `:colorscheme` and `:set theme=`, `background=` are two entry points to one switch (the theme built once at `editor_assembly.rb:594`), not independently testable; one test table; the brief says run it as queued; areas 12 (ex commands, completion), 13 (screen presenter), 14 (themes, sgr table, set handler), wiring in 4.
- Order (T2): pool kept, 0 pushed back; buffer-picker next (pushed back 1 for set-options' split parts, now all delivered).
- Retro placed (T1): hidden-option note 2 (scout 31.3 percent, 62,344 of 199,387 output, 3 packs for 2 planned areas) is backlog Pool 8 areas-in-plan and Pool 10 scout-prune evidence, note 3 (merge 14.6 percent, 6 waits on a 12.0 min CI) Pool 8 merge-wait-bound, note 4 (package plus prtext 22 of 172 calls, 0 findings) a backlog.md entry near Pool 10 pr-claims; spinel-catchup-b notes 2 to 4 already in Pool 8, 10; the backlog queue untouched by this lane.
