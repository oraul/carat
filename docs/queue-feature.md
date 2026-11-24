# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 33

Held: no item starts until the user lifts the hold of 2026-11-23 (Decisions).

1. `explorer-look` (T2 user request, estimated medium). Where: `carat/plugins/explorer/plugin.rb:66` and `:517` (width 30), `carat/adapters/frame_presenter.rb:888` paint_marked_row, `carat/domain/icons.rb:22` (nerd `current` U+F054). Why: `docs/design.md:136` sets 36 columns; the current row drops its icon's file-type color, its label is not bold, and the nerd set's marker is still a chevron (3 explorer-rows findings). Outcome: the tree opens 36 wide and its current row reads as design section 8 says. Accepted when an `editor_explorer` width row and `adapters_frame_presenter` rows for the icon group, the bold label, and the nerd bar fail before. Backlog: "### The nerd set's current marker is still a chevron", "### The current row's icon loses its file-type color", "### The current row's label is not bold".
2. `background-theme` (T2 user request, estimated medium, pushed back 6, critical d carat/drivers/ansi_terminal.rb). Where: `carat/drivers/ansi_terminal.rb:79` read_key's OSC 11 reply. Why: an unanswered query keeps the reader awaiting the whole session, a late reply's tail and a reply split inside its introducer reach the keys as typed text. Outcome: the reply is read within a bound and never reaches the keys. Accepted when driver rows for an unanswered, a late, and a split reply fail before. Backlog: "### An unanswered OSC 11 query keeps the terminal awaiting for the whole session (sprint-22 sweep quality)", "### A late OSC 11 reply's tail is read as keys", "### An OSC 11 answer split inside its introducer reaches the keys (sprint-22 sweep quality)".
3. `finder-path-safe` (T2 user request, security Low (6), estimated medium, pushed back 6, critical a carat/domain/frame.rb). Where: `carat/domain/frame.rb:181` put_from (tab names at `carat/adapters/tab_bar.rb:207`, the status bar, floats, menus); `carat/domain/display_width.rb:190` against `carat/plugins/finder/safe_text.rb:71`. Why: a project file named with U+202E reorders the tab row (sprint-32 Low (6)); two code point tables differ (U+2060 to U+2065). Outcome: names outside buffer lines show format code points as markers, widths matching; one table. Accepted when a frame test of a tab name holding U+202E fails before; finder rows with U+202E confirmed blank. Backlog: "### Frame#put_from writes bidirectional and zero-width format code points raw (security Low (6))", "### Names and menus still draw format code points raw", "### Two tables of the format code points drift apart at carat/domain/display_width.rb:190 (sprint-32 review quality)", "### Grep.safe passes bidi and zero-width format code points into rows", "### The file finder shows paths as the file lists them".

## Pool

1. `sidebar-head-tidy` (T6, estimated medium, area 13): surface-edges-fix's 4 headings; `frame_presenter.rb:765` repeats `slot.rb:78`, `:715` reads the branch through the status bar.
2. `tab-bar-tidy` (T6, estimated small): "### The tab mark under a focused float"; tab-name-parent's re-scan per width (`tab_bar.rb:213`, sweep note 46) and stale first-tab spec scenarios.
3. `terminal-colors` (T6, estimated medium, area 13): ui-groups-c's 3 findings: NO_COLOR still writes `38;5;`, 16-color StatusLine and StatusLineDim differ by bold only, `TERM=xterm` read as 256.
4. `explorer-folders` (T2 user request, estimated small): folder colors.
5. `finder-word`, `panel-surface` (T2, estimated small each): 3 headings.
6. Facet waves (T2 user request, estimated medium each): `dim-backdrop`, `float-polish`, `separator-styles`, `glyph-audit`, `plugin-ui-tokens` (disputed Low (3)), `finder-refined`, `key-hints-dock`, `start-gem`, `diagnostic-text`, `explorer-git`.
7. `finder-preview-gutter` (estimated small), `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops`, `search-count` (T2, estimated medium each, pushed back 5 to 9, reason: the user's explorer, terminal, and name-safety items first).
8. `vim-folds-d`, `markdown-reading-e` (T2, estimated medium each, pushed back 5, 9, reason: UI first).
9. Async and debugger (T2 user request, estimated medium each, pushed back 5, reason: UI first): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming`, `program-jobs`, `socket-probe`, `debug-keys`, `debug-breakpoints`, `debug-channel`, `debug-session` (large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
10. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 8, reason: after the UI track); `git-panel`, `lint-panel`, `claude-bridge`, `claude-workflow` (T2, estimated large each); `dockerfile-support`, `containers-panel`, `containers-logs` (T2 user request, estimated medium each).
11. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, estimated medium each).
12. T5 (estimated medium each, pushed back 10, reason: after the UI track): `theme-tuning`, `semantic-highlight` (large), `plugin-protocol-a`, `formatting`, `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax`, `csv-viewer` (large).
13. `bidi-controls` (T3 security Low, estimated small, pushed back 16, reason: its name part is Sprint 33 item 3): sprint-30 sweep notes 34 (finder preview rows), 45 (explorer names, check at HEAD), soft hyphen; `insert-copy` (T4, estimated small).

## Decisions

- Security first (T0): none; sprint-32 review 3 Lows (6), (6), (4), sweep 3 Lows (5), (4), (3), none High or Medium, none disputed.
- 3 features, 3 backlog (T2): items 1 to 3 from Pool 3, 7, 8 of sprint-32's queue, the user's tab and explorer items behind the pushed-back reason delivered (explorer-rows, tab-name-parent).
- Hold (T2 user request, 2026-11-23, "Go this sprint and after on hold"): Sprint 33 is planned, none starts until lifted.
- Aging (T2): `background-theme` and `finder-path-safe` pushed back 6, drawn now.
- Size (T2): medium each, 2 to 3 testable parts in one area; the last two rows under budget (tab-name-parent 561,129 on 2.5M, ui-groups-c 712,345 on 1.2M), no size-up; explorer-rows went over (1,412,911 on 1.2M).
- Placed (T6): ui-groups-c findings as Pool 3; tab-name-parent findings as Pool 2; explorer-rows findings in item 1.
