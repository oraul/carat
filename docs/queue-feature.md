# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 32

Delivered: `explorer-rows` (69e59b6, #330), `tab-name-parent` (this delivery).

1. `ui-groups-c` (T2, estimated medium, split from ui-groups-b): Where: `carat/domain/highlight.rb:166` (ModeMsg and MoreMsg, which no painter draws), `test/adapters_status_bar.rb` (NO_COLOR and 16 colors proven on group ids only). Why: 2 groups a theme sets change nothing on screen; the bytes a terminal gets at `TERM=xterm` and under NO_COLOR are untested. Outcome: ModeMsg and MoreMsg are drawn where Neovim draws them or removed; the bars' bytes at 16 colors and NO_COLOR are proven. Accepted when a pty smoke case at `TERM=xterm` and NO_COLOR comparing StatusLine and StatusLineDim bytes fails before. Backlog: "### The visual indicator is dim but ModeMsg and MoreMsg are still unused", "### NO_COLOR and 16 colors are proven on the groups, not on the terminal bytes".

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

- Security first (T0): none; the sprint-31 review 0 security findings, none disputed; the 3 pending runs carry no periodic finding.
- Restored (T1 pipeline defect): #330 rewrote this queue to the tab-focus-mark plan (Sprint 31, 3 Pool items lost); the Sprint 32 queue of 092d282 is the base; evidence in `backlog.md`.
- Delivered (T2 user request): `tab-name-parent`, Sprint 32 item 2; `explorer-rows` (#330, 1,412,911 total, medium, over 1.2M) removed.
- Size up (T2): medium on content (ui-groups-b 545,902, surface-edges-fix 567,768, one-accent-tabs 867,943); the last two over (tab-focus-mark 46 minutes on small's 25, explorer-rows 1,412,911 on 1.2M): large.
- Not split (T2): 2 parts in 2 map areas, the name and gap in `tab_width` and `paint_tab`, one dead member; the large is the size-up, not the content.
- Critical (T2): d carat/domain/buffer.rb, the icon member's removal.
- Placed (T1): explorer-rows retro 14, 15 and notes 3, 4 into `backlog.md`; head-form, hand pr (#329 fixed wait) and the escape note (Pool 15 `check-escape-lane-build`) dropped; review-in-openspec 9 to 12 already in backlog Pool 18.
