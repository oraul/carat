# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 32

1. `explorer-rows` (T2 user request, estimated medium): Where: `carat/plugins/explorer/tree.rb:114` (the root row naming the project, which `carat/adapters/tab_bar.rb:130` now heads the column with), `tree.rb:171` (the current file's one-cell mark). Why: the user's first feature of Sprint 32; the tree spends its first row repeating the head, and its current row differs from `docs/design.md:136` (full-width highlight, sapphire bar). Outcome: the tree starts at the root's entries, and the current row reads as `docs/design.md:136` says. Accepted when `editor_explorer` test rows for the tree's first row and its current row fail before. Backlog: none.
2. `tab-name-parent` (T2 user request, estimated medium): Where: `carat/adapters/tab_bar.rb:185` (the name from `name_start`), `:33` (`FRAME_CELLS` 4), `:233`; `carat/domain/buffer.rb:130`, `:259` (`icon` set on every path change, read by 0 callers since one-accent-tabs). Why: two open `x.rb` files show two identical tabs; neighbouring tabs stand 3 blank cells apart against the spec's 2. Outcome: a dim parent folder precedes the name only while two listed files share it; tabs are 2 blank cells apart; the buffer keeps no unread icon. Accepted when `adapters_tab_bar` test rows for `a/x.rb` beside `b/x.rb` and for the gap between two tabs fail before. Backlog: "### Neighbouring tabs are three cells apart, not two", "### Buffer#icon may be unused after the tab icon is gone".
3. `ui-groups-c` (T2, estimated medium, split from ui-groups-b): Where: `carat/domain/highlight.rb:166` (ModeMsg and MoreMsg, which no painter draws), `test/adapters_status_bar.rb` (NO_COLOR and 16 colors proven on group ids only). Why: 2 groups a theme sets change nothing on screen; the bytes a terminal gets at `TERM=xterm` and under NO_COLOR are untested. Outcome: ModeMsg and MoreMsg are drawn where Neovim draws them or removed; the bars' bytes at 16 colors and NO_COLOR are proven. Accepted when a pty smoke case at `TERM=xterm` and NO_COLOR comparing StatusLine and StatusLineDim bytes fails before. Backlog: "### The visual indicator is dim but ModeMsg and MoreMsg are still unused", "### NO_COLOR and 16 colors are proven on the groups, not on the terminal bytes".

## Pool

1. `sidebar-head-tidy` (T6, estimated medium, area 13): surface-edges-fix's 4 headings (head groups, `:cd` leaves the project name, right sidebar, narrow cut); sprint-31 review: `frame_presenter.rb:765` repeats `slot.rb:78` headed?, `:715` reads the branch through the status bar, `tab_bar.rb:132` a third basename copy.
2. `tab-float-mark` (T6, estimated small): "### The tab mark under a focused float" (`tab_bar.rb` selected_buffer).
3. `explorer-look` (T2 user request, estimated small): width 30 at `carat/plugins/explorer/plugin.rb:66` against `docs/design.md:136`'s 36; folder colors.
4. `finder-word`, `panel-surface` (T2, estimated small each): 3 headings.
5. Facet waves (T2 user request, estimated medium each): `dim-backdrop`, `float-polish`, `separator-styles`, `glyph-audit`, `plugin-ui-tokens` (disputed Low (3)), `finder-refined` (3 headings), `key-hints-dock`, `start-gem`, `diagnostic-text`, `explorer-git`.
6. `finder-preview-gutter` (estimated small), `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops`, `search-count` (T2, estimated medium each, pushed back 5 to 9, reason: the user's tab and explorer items first).
7. `background-theme` (T2 user request, estimated medium, pushed back 6, reason: the user's tab and explorer items first, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries, `ansi_terminal.rb:79`.
8. `finder-path-safe` (T2 user request, security Lows, estimated medium, pushed back 6, reason: the user's tab and explorer items first, critical a carat/plugin_api.rb): its headings at 24e3738 less plugin-host-lows'.
9. `vim-folds-d`, `markdown-reading-e` (T2, estimated medium each, pushed back 5, 9, reason: UI first).
10. Async and debugger (T2 user request, estimated medium each, pushed back 5, reason: UI first): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming`, `program-jobs`, `socket-probe`, `debug-keys`, `debug-breakpoints`, `debug-channel`, `debug-session` (large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
11. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 8, reason: after the UI track); `git-panel`, `lint-panel`, `claude-bridge`, `claude-workflow` (T2, estimated large each); containers (T2 user request, estimated medium each): `dockerfile-support`, `containers-panel`, `containers-logs`.
12. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, estimated medium each).
13. T5 (estimated medium each, pushed back 10, reason: after the UI track): `theme-tuning`, `semantic-highlight` (large), `plugin-protocol-a`, `formatting`, `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax`, `csv-viewer` (large).
14. `bidi-controls` (T3 security Low, estimated small, pushed back 15, reason: the file text part moved to the backlog lane's `render-text-lows`): sprint-30 sweep notes 34 (finder preview rows), 45 (explorer names); `insert-copy` (T4, estimated small).

## Decisions

- Security first (T0): none; the sprint-31 review recorded 0 security findings (High 0, Medium 0), none disputed; the 2 pending runs carry no periodic finding.
- 3 features, 3 backlog (T2 user request): `explorer-rows` (the user's first of Sprint 32), `tab-name-parent`, `ui-groups-c`, Pool 1 to 3.
- Size (T2): medium each; ui-groups-b 545,902 and surface-edges-fix 567,768 total (medium, under 1.2M); one-accent-tabs, sized small, ran 867,943 (retro 7: size by files touched), so `tab-name-parent` (2 code files, 3 snapshot files) is medium; the last two rows are not both over.
- Split (T2): `explorer-rows` keeps the 2 row parts, width and folder colors go to Pool 3; `ui-groups-c` keeps 2 parts, the head's groups go to Pool 1: 3 testable parts each otherwise.
- Folded (T6): Buffer#icon (0 readers at 6f0ecc3) and the 3-cell tab gap into `tab-name-parent`, the same file; the color-themes count entry is filed by groom.
- Moved (T3): line_painter's format characters (sprint-22 Low (6), sprint-30 note 3) to the backlog lane's `render-text-lows`, backlog-pick batch 3; `bidi-controls` keeps notes 34, 45.
- Review (T6): sprint-31 quality 0 blocking, 6 advisories; 3 into Pool 1, all 6 in `groomed.md`.
