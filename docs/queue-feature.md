# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 31

1. `surface-edges-fix` (T2 user request, estimated medium): Where: `carat/adapters/tab_bar.rb:26` to `:30` (SEPARATOR, FRAME_CELLS), `:49`, `:50`, `:82`, `:147` (the separator write); `carat/adapters/frame_presenter.rb:261` (TabBar#paint gets only cols), `:616` (PaintedRows::TILDE), `:741` to `:757` (paint_header). Why: the user's photos of 2026-11-23: a `│` after every tab, the tab row painted from column 0, not the editor's first column, a separate explorer head row, and `~` rows in the sidebar; the design draws no separator glyph. Fix outline: no tab separator; tabs start at the sidebar's col + width + 1 (column 0 with no sidebar); row 0 over the sidebar reads `carat · main` (project bright, `·` faint, branch dim), a head row only while the slot holds two views; blank sidebar rows. The dashed line at the sidebar edge is the terminal's padding: no carat fix (user). Accepted when a frame snapshot at 80 columns with the sidebar and two tabs, at truecolor, 16 colors, and NO_COLOR, shows no `│`, the first tab at the editor's first column, and no `~` in the sidebar, failing before.
2. `one-accent-tabs` (T2 user request, estimated medium): Where: `carat/domain/themes.rb:116` (TabLineSel), `carat/adapters/winbar.rb:39`, `:55`, `carat/adapters/tab_bar.rb:122` (page numbers), `:136` (tab icon), `carat/adapters/frame_presenter.rb:751`. Why: sapphire fills mark the current tab, the winbar name, the page numbers, and the view names, against one accent per surface. Fix outline: TabLineSel FG on BG bold; one new bold no-fill group for the winbar name, the page numbers (current bold, others dim), and the view names; no tab icon; under 16 colors and NO_COLOR the active tab bold, inactive names the normal foreground; a `docs/compatibility.md` line: gt moves between buffer tabs, tab pages are the numbers at the right. Accepted when tab row snapshots at 24-bit, 256, 16 colors, and NO_COLOR fail on today's fill.
3. `tab-focus-mark` (T2 user request, estimated small): Where: `carat/adapters/tab_bar.rb:53`, `:92`. Why: with the explorer focused no tab is marked. Fix outline: the file window's tab stays marked while a sidebar has focus. Accepted when a test focusing the explorer shows the file's tab selected, failing before.

## Pool

1. `explorer-rows` (T2 user request, estimated medium): Sprint 32's first feature (user); also drops the tree's `carat` root row.
2. `tab-name-parent` (T2 user request, estimated small): a dim parent folder only when two open files share a name; after the tab changes.
3. `ui-groups-c` (T2, estimated medium, split from ui-groups-b): ModeMsg and MoreMsg used or removed (`frame_presenter.rb:1133`, `themes.rb:131`); a pty smoke case at `TERM=xterm` and NO_COLOR comparing StatusLine and StatusLineDim bytes. "### The visual indicator is dim but ModeMsg and MoreMsg are still unused", "### NO_COLOR and 16 colors are proven on the groups, not on the terminal bytes".
4. `finder-word`, `panel-surface` (T2, estimated small each): 3 headings.
5. Facet waves (T2 user request, estimated medium each): `dim-backdrop`, `float-polish`, `separator-styles`, `glyph-audit`, `plugin-ui-tokens` (disputed Low (3)), `finder-refined` (3 headings), `key-hints-dock`, `start-gem`, `diagnostic-text`, `explorer-git`.
6. `finder-preview-gutter` (estimated small), `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops`, `search-count` (T2, estimated medium each, pushed back 4 to 8, reason: the user's tab changes first).
7. `background-theme` (T2 user request, estimated medium, pushed back 5, reason: the user's tab changes first, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries, `ansi_terminal.rb:79`.
8. `finder-path-safe` (T2 user request, security Lows, estimated medium, pushed back 5, reason: the user's tab changes first, critical a carat/plugin_api.rb): its headings at 24e3738 less plugin-host-lows'.
9. `vim-folds-d`, `markdown-reading-e` (T2, estimated medium each, pushed back 4, 8, reason: UI first).
10. Async and debugger (T2 user request, estimated medium each, pushed back 4, reason: UI first): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming`, `program-jobs`, `socket-probe`, `debug-keys`, `debug-breakpoints`, `debug-channel`, `debug-session` (large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
11. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 7, reason: after the UI track); `git-panel`, `lint-panel`, `claude-bridge`, `claude-workflow` (T2, estimated large each); containers (T2 user request, estimated medium each): `dockerfile-support`, `containers-panel`, `containers-logs`.
12. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, estimated medium each).
13. T5 (estimated medium each, pushed back 9, reason: after the UI track): `theme-tuning`, `semantic-highlight` (large), `plugin-protocol-a`, `formatting`, `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax`, `csv-viewer` (large).
14. `bidi-controls` (T3 security Lows (6), (3), estimated small, pushed back 14, reason: the user's tab changes first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))", sprint-30 sweep notes 3 (`line_painter.rb:48`, Low (3)), 34 (finder preview rows), 45 (explorer names); `insert-copy` (T4, estimated small).

## Decisions

- Security first (T0): none; sprint-30 review High 0, Medium 0, Low 1 (`tools/gates.sh:662`, Low (6)); sweep High 0, Medium 0, Low 4; none at confidence 8.
- Sprint 31 (T2 user request): the user's request of 2026-11-23 (plugin-host-lows notes 6, 7) names its three features in order; 3 features, 3 backlog.
- Not split (T2): surface-edges-fix is the user's one change, one snapshot over 2 files of area 13.
- Estimated (T2): prompt-in-float 895,682, recent-files-persist 927,740, ui-groups-b 545,902 total tokens, none over 1.2M: medium; tab-focus-mark small, 2 lines of one file.
- Not critical (T2): no path of rules a to d.
- Placed (T2): `design-drift-sync` in the backlog lane (user); sweep Low (3) and notes 34, 45 into `bidi-controls`.
