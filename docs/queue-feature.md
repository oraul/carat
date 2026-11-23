# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 31

All three features delivered: `surface-edges-fix` (0773c27, #322), `one-accent-tabs` (38642f0, #325), `tab-focus-mark` (this delivery); the sprint closes at its review.

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

- Security first (T0): none; sprint-30 review High 0, Medium 0, Low 1 (`tools/gates.sh:662`, Low (6)); the 3 pending runs carry no periodic finding.
- Delivered (T2 user request): `tab-focus-mark`, Sprint 31's third feature; with the explorer focused the current window is the sidebar's, whose buffer has no tab (`tab_bar.rb:73`, `:91`), so 0 tabs are marked.
- Removed (T2): `surface-edges-fix` merged at 0773c27 (567,768 total, medium, under 1.2M) and `one-accent-tabs` at 38642f0 (867,943 total, small, over 500k).
- Estimated small, not split (T2): one code file and one test, no shared table (one-accent-tabs retro note 7: size by files touched); the last two feature runs not both over (567,768 under medium).
- Not critical (T2): `carat/adapters/tab_bar.rb` is under no rule a to d.
- Kept (T2): Pool order unchanged; `explorer-rows` stays Sprint 32's first feature (user); `tab-name-parent` now follows the delivered tab changes.
- Placed (T1): one-accent-tabs retro note 8 (package 45,250 output in 10 calls, 18 percent) into `backlog.md`, near the backlog lane's `package-one-start`; review-in-openspec notes 9 to 11 already in that lane's Pool 12; head-form and overrun notes dropped: heads read from git, overruns cited above.
