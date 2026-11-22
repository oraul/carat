# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 28

1. `ui-groups` (T2 user request, estimated medium, pushed back 6): Where: `carat/adapters/status_bar.rb:78` (`paint`), `:219`, `:330`; `docs/design.md:42` (PANEL_DIM `#a4aabd` 5.4:1, light `#5c6173`), `:147`. Why: council (4) of 2026-11-21 puts it after float-painter, before window-surfaces; no PANEL_DIM in the bar. Fix outline: the bar groups of `docs/design.md:147` and the message row's indicators; sapphire fill on the mode pill only. Accepted when frame snapshots show each group's color and spacing, PANEL_DIM at least 4.5:1, at 16 colors and NO_COLOR too. Backlog: none.
2. `picker-speed` (T2 user request, estimated medium, pushed back 2): Where: `bench/run.sh:69` (the default list omits `lh-float`, `palette`); `make bench-budget`. Why: council (4) asks a float, finder, and palette speed gate before window-surfaces; no budget covers them (grep 774.4 allocations in each of the last 10 backlog rows). Fix outline: those scenarios run by default with budgets. Accepted when `make bench` runs them and `bench-budget` fails on a doubled figure. Backlog: "### the default scenario list omits lh-float, lh-winbar, n, palette at bench/run.sh:69 (sprint-26 sweep quality, note 31)".
3. `finder-switch` (T2 user request, estimated medium, pushed back 2): moving between files and grep loses the query; grepping the word under the cursor needs typing. Where: `carat/plugins/finder/plugin.rb:52` (keymap lines), `live_prompt` `carat/plugin_api.rb:899`. Fix outline: `<C-g>` switches keeping the query; `<leader>fw` greps the word under the cursor; no API change. Accepted when tests switch both ways keeping the query and `<leader>fw` on a word and a blank opens grep with it or empty, with `docs/actions.md` rows. Backlog: none.

## Pool

1. `finder-rows` (T2 user request, estimated large, pushed back 4, reason: the user's order of 2026-11-21, critical e carat/plugins/finder/plugin.rb); `recent-files-persist` (T2, small): "### The recent files are kept for one run only".
2. Facet waves 3 to 5 (T2 user request, estimated medium each): `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish` ("### The float key's layout is read in two classes at carat/adapters/frame_presenter.rb", sprint-27 note 6), `separator-styles`, `one-accent`, `glyph-audit`; `plugin-ui-tokens` ("### style_float checks a span's start column only from below (sprint-23 review security Low (3), disputed)"), `finder-refined`, `key-hints-dock`, `explorer-rows`; `start-gem`, `diagnostic-text`, `explorer-git`.
3. `finder-preview-gutter` (T2, small, pushed back 1); `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops` (medium each, pushed back 1); `search-count` (medium, pushed back 5).
4. `background-theme` (T2 user request, estimated medium, pushed back 2, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries, sweep note 51 (`ansi_terminal.rb:83`).
5. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 2, critical a carat/plugin_api.rb): its 4 headings at 24e3738, less those backlog Pool 1 lists.
6. `vim-folds-d` (T2, estimated medium, pushed back 1): "### The closed fold's text is not the design's chevron and count", "### The fold label's fill is not ASCII under option.icons ascii and NO_COLOR"; `markdown-reading-e` (T2, medium, pushed back 5, reason: no location).
7. Async (T2 user request, estimated medium each, pushed back 1): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` (2 headings at 24e3738), `program-jobs`; debugger: `socket-probe`, `debug-keys` (small), `debug-breakpoints`, `debug-channel`, `debug-session` (large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
8. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, medium each, pushed back 4, reason: after the UI track); `git-panel`, `lint-panel` (T2, large, pushed back 5, 2); `claude-bridge`, `claude-workflow` (T2 ideas, large).
9. Containers (T2 user request, medium each, after the Facet waves and finder work): `dockerfile-support` (small), `containers-panel` (`<leader>C`), `containers-logs` (after plugin-tasks), the rest as the notes of 2026-11-21 slice them.
10. `vim-increment` (T2, small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, medium each).
11. `theme-tuning`, `semantic-highlight` (T5 roadmap, medium, large); `plugin-protocol-a`, `formatting` (T5, medium, pushed back 2); `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, medium each).
12. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, medium each, pushed back 6, reason: after the UI track); `csv-viewer` (T5, large, pushed back 10).
13. `bidi-controls` (T3 Lows, small, pushed back 11, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, small).

## Decisions

- Security first (T0): none; sprint-27 review High 0, Medium 0, Lows (6), (4), (3); no `review.periodic` in the 3 pending runs.
- Sprint 28 (T2): 3 features, 3 backlog; ui-groups, picker-speed by council (4) of 2026-11-21, then finder-switch (Pool 2's first); finder-rows pushed back 4, the user's order.
- Size (T2): ui-groups small to medium, no feature row of the last 7 under 1,040,616 (folded-row); last two under budget, no size up.
- Findings (T2): buffer-picker, folded-row, float-painter feature headings placed in Pool 1, 2, 6.
