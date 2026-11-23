# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 32

Delivered: `explorer-rows` (69e59b6, #330), `tab-name-parent` (#333), `ui-groups-c` (this delivery). No feature item is left; the hold draws none until lifted.

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

- Security first (T0): none; the pending runs merge-git-unpin, review-in-openspec, and tab-name-parent carry no periodic finding; the sprint-31 review 0 security findings, none disputed.
- Delivered (T2): `ui-groups-c`, Sprint 32 item 1; with `explorer-rows` and `tab-name-parent` (561,129 total, rework 0) the sprint's 3 features are done.
- Size (T2): medium, 2 parts (2 groups no painter draws at `highlight.rb:166`; the bars' bytes at `TERM=xterm` and NO_COLOR) against ui-groups-b's 545,902 medium; no size-up: of the last two, explorer-rows went over (1,412,911 on 1.2M), tab-name-parent stayed under (561,129 on 2.5M).
- Not split (T2): 2 independently testable parts, under 3, in the highlight and bars areas.
- Not critical (T2): no path of rules a to d; the smoke case is a test.
- Hold (T2 user request, 2026-11-23, "Go this sprint and after on hold"): no Pool item drawn into Sprint 32.
- Placed (T1): merge-git-unpin retro note 4 (a Low (6) restating a recorded user decision started a fix round and a close-advisories start; note 5: 5 of the last 10 backlog rows rework 1 or more) into `backlog.md` for the backlog lane; head-form notes (merge-git-unpin 1 to 3 and 6, tab-name-parent 1 and 2) dropped: they escalate nothing; review-in-openspec 8 to 12 already in backlog Pool 18.
