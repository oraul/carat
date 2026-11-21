# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 26

1. `set-options` (T2 user request, estimated large, critical e carat/use_cases/ex/set_command_handler.rb): Where: `carat/use_cases/ex/set_command_handler.rb:29` (PENDING answers Not implemented for number, relativenumber, tabstop, shiftwidth, expandtab, autoindent, scroll, scrolloff, timeoutlen, undolevels), `carat/domain/options.rb`. Why: the design council of 2026-11-21 (2), the basics: `hidden` on by default, `:colorscheme`, numeric options, the boolean switches; 4 entries. Fix outline: each pending option read and set by `:set`, `hidden` on by default, `:colorscheme` switching the theme; PENDING's 5 omitted names are config-guards-b's. Accepted when a table-driven test per option and colorscheme fails before the fix, each has a compatibility row, and `make gen-config` is current. Backlog: "## :set handles only filetype, syntax, the search options, and cursorline", "## The boolean options of :set are three parallel switches with a silent default", "## :set jumptab answers E518 while :set breadcrumbs answers Not implemented", "## Two shipped options are accepted and dropped, and Config settings are untyped".
2. `buffer-picker` (T2 user request, estimated large, critical e carat/plugins/finder/plugin.rb): Where: `carat/plugins/finder/plugin.rb`, its manifest's keymap lines. Why: council (2), (3): no picker lists buffers or recent files and a search cannot be resumed. Fix outline: `<leader>fb` buffers, `<leader>fr` recent files (bounded), `<leader>fR` resumes the last search (finder-resume folded in). Accepted when a table-driven test per key, frame rows of each picker in both themes and ascii, and `docs/actions.md` rows pass. Backlog: none.
3. `folded-row` (T2 user request, Facet wave 2, estimated large, pushed back 1, critical e carat/adapters/frame_presenter.rb): Where: the fold row of `carat/adapters/frame_presenter.rb` (`:799` at 7156f43). Why: a closed fold paints as one Normal row, unlike `docs/design.md`'s Folded. Fix outline: the Folded group, padded to the window. Accepted when frame rows show it in both themes, ascii, 16 colors, and NO_COLOR (the Normal row fails before). Backlog: none.

## Pool

1. `float-painter` (T2 user request, estimated medium); `ui-groups` (T2, small, pushed back 5, reason: the waves): PANEL_DIM, the message row's indicators; `picker-speed` (T2, medium, pushed back 1).
2. `finder-switch` (T2 user request, estimated medium, pushed back 2, reason: the basics); `finder-rows` (T2, large, pushed back 3, reason: the user's order of 2026-11-21, critical e carat/plugins/finder/plugin.rb).
3. Facet waves 3 to 5 (T2 user request, estimated medium each): `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`, `separator-styles`, `one-accent`, `glyph-audit`; `plugin-ui-tokens` ("### style_float checks a span's start column only from below (sprint-23 review security Low (3), disputed)"), `finder-refined`, `key-hints-dock`, `explorer-rows`; `start-gem`, `diagnostic-text`, `explorer-git`.
4. `finder-preview-gutter` (T2, estimated small, pushed back 1); `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops` (medium each, pushed back 1); `search-count` (medium, pushed back 5).
5. `background-theme` (T2 user request, estimated medium, pushed back 2, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries.
6. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 2, critical a carat/plugin_api.rb): its 4 headings as listed at 24e3738.
7. `vim-folds-d` (T2, estimated medium, pushed back 1); `markdown-reading-e` (T2, medium, pushed back 5, reason: no location).
8. Async (T2 user request, estimated medium each, pushed back 1): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` (2 headings at 24e3738), `program-jobs`; then the debugger (council of 2026-11-21): `socket-probe` (small), `debug-keys` (small), `debug-breakpoints`, `debug-channel`, `debug-session` (large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
9. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track); `git-panel` (T2, large, pushed back 5); `claude-bridge`, `claude-workflow` (T2 ideas, large); `lint-panel` (T2, large, pushed back 2).
10. Containers (T2 user request, estimated medium each, after the Facet waves and finder work): `dockerfile-support` (estimated small), `containers-panel` (medium, the engine port inside its directory, `<leader>C`), `containers-logs` (medium, after plugin-tasks), the rest as the notes of 2026-11-21 slice them.
11. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, medium each).
12. `theme-tuning`, `semantic-highlight` (T5 roadmap, estimated medium, large); `plugin-protocol-a`, `formatting` (T5, medium, pushed back 2); `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, medium each).
13. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track); `csv-viewer` (T5, large, pushed back 10).
14. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, small).

## Decisions

- Security first (T0): none; sprint-25 review High 0, Medium 0 at 8+; 0 review.periodic in 3 pending runs.
- Sprint 26 (T2, council note 29 (2)): 3 features, 3 backlog: set-options, buffer-picker, folded-row, Pool 1 to 3 in order; the feature lane waits while spinel-catchup-b runs alone (note 38).
- Size (T2): large each, one up; the lane's last two medium over 1.2M (showtabline 1,365,817; cmdline-editing 1,418,893 in 131 min).
- Placed (T2, cmdline-completion notes 14 to 19, 26, 30): containers in Pool 10, the debugger in Pool 8 after program-jobs; in neither queue before.
- Retro (T1): cmdline-completion 1 to 3 into backlog Pool 8, 10; 0 blocking quality at the close; note 2's bug is backlog Pool 3.
