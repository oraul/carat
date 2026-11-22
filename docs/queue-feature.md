# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 27

1. `buffer-picker` (T2 user request, council (2), (3), estimated large, pushed back 1, critical e carat/plugins/finder/plugin.rb): Where: `carat/plugins/finder/plugin.rb:101` binds only `<leader>ff`, `<leader>fg`, `<C-p>`. Why: the council of 2026-11-21 approved (2) a buffer picker with recent files and (3) `<leader>fr`, `<leader>fR`; 0 of the 3 keys bound. Fix outline: `<leader>fb` open buffers, `<leader>fr` recent files (bounded), `<leader>fR` resumes the last search. Accepted when a test per key passes, frame rows in both themes and ascii, `docs/actions.md` rows. Backlog: none.
2. `folded-row` (T2 user request, Facet wave 2, estimated large, pushed back 2, critical e carat/adapters/frame_presenter.rb): Where: the closed-fold row of `carat/adapters/frame_presenter.rb` (`:813`, `:799` at 7156f43). Why: it paints Normal, not `docs/design.md`'s fold row look. Fix outline: paint it in its own theme group. Accepted when frame rows in both themes, ascii, 16 colors, and NO_COLOR show it. Backlog: none.
3. `float-painter` (T2 user request, council (4), estimated medium): Where: `carat/adapters/frame_presenter.rb:649` (`paint_floats`), `:669`, `:712`, in a class of 1469 lines and 60 methods. Why: council (4) puts it before window-surfaces; sprint-26 sweep note 35. Fix outline: floats and notifications painted by a collaborator, as StatusBar, Winbar, TabBar were, the window path explicit. Accepted when every frame snapshot is unchanged, `lh-float` time and allocations held, the map updated. Backlog: "### 1469 lines and 60 methods paint windows, headers, winbars at carat/adapters/frame_presenter.rb:1 (sprint-26 sweep quality, note 35)".

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

- Security first (T0): none; sprint-26 review High 0, Medium 0, Lows (5), (4), (3); periodic security at 3370625 high=0 medium=0 low=3.
- Sprint 27 (T2): 3 features, 3 backlog; buffer-picker, folded-row, float-painter, the pool's first three (council of 2026-11-21 (2), (3), (4)); ui-groups pushed back 6 with its reason.
- Size (T2): buffer-picker, folded-row large, critical e (colorscheme-command 1,156,082 in 73 min, set-options 1,285,703 in 86); float-painter medium (hidden-option 1,099,813 in 68); the last two feature rows under budget, no size up.
- Groom (T2): set-options listed 4 headings; feature findings filed by groom: hidden-option 1 (`walk_jumps.rb:49`, also in backlog sweep-bugs), set-options 3 (`:set theme` fixed since by colorscheme-command b95cff4).
