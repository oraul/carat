# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 30

Drained: `prompt-in-float` (#314), `recent-files-persist` (#319), and `ui-groups-b` delivered; the next sprint is drawn by `/sprint`.

## Pool

1. `ui-groups-c` (T2, estimated medium, split from ui-groups-b): Where: `carat/adapters/frame_presenter.rb:1133` (`paint_message`, the `-- VISUAL --` lines `:1144` to `:1148` in MESSAGE_DIM); `carat/domain/themes.rb:131`, `:132` (MESSAGE_MODE, MESSAGE_MORE); `carat/domain/highlight.rb:42`, `:43`, `:165`; `test/domain_theme.rb:665`; `test/smoke_editor.rb` (area 18); `carat/drivers/ansi_terminal.rb:32`, `:33` (read only). Why: ModeMsg and MoreMsg have 0 callers; NO_COLOR and 16 colors are proven on groups, not on the bytes the terminal gets. Fix outline: ModeMsg and MoreMsg used or removed by design section 8; a smoke case at `TERM=xterm` and under `NO_COLOR`. Accepted when a snapshot shows the group choice and the smoke case compares the StatusLine and StatusLineDim sequences at 16 colors and under NO_COLOR, failing before. Backlog: "### The visual indicator is dim but ModeMsg and MoreMsg are still unused", "### NO_COLOR and 16 colors are proven on the groups, not on the terminal bytes".
2. `finder-word` (T2, estimated small): "### Space f w takes no word to the right of a blank cursor", "### word_at counts every non-ASCII character as a word character"; `panel-surface` (T2, estimated small): "### The bottom panel is not on the darker surface".
3. Facet waves 4 and 5 (T2 user request, estimated medium each): `dim-backdrop`, `float-polish` ("### The float key's layout is read in two classes at carat/adapters/frame_presenter.rb"), `separator-styles`, `one-accent`, `glyph-audit`; `plugin-ui-tokens` (a disputed Low (3)), `finder-refined` ("### The grep preview's matched line has the bar but no fill or color", "### The finder's rows lack the dim folder and the sapphire matched letters", "### The finder styles its rows with group ids it never checks"), `key-hints-dock`, `explorer-rows`; `start-gem`, `diagnostic-text`, `explorer-git`.
4. `finder-preview-gutter` (T2, estimated small, pushed back 3); `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops` (T2, estimated medium each, pushed back 3); `search-count` (T2, estimated medium, pushed back 7); reason: Facet waves first.
5. `background-theme` (T2 user request, estimated medium, pushed back 4, reason: Facet waves first, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries; the session-long OSC 11 wait (`ansi_terminal.rb:79`).
6. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 4, reason: after plugin-host-lows, critical a carat/plugin_api.rb): its 4 headings at 24e3738 less those plugin-host-lows lists.
7. `vim-folds-d` (T2, estimated medium, pushed back 3, reason: UI first): 2 fold label headings; `markdown-reading-e` (T2, estimated medium, pushed back 7, reason: no location).
8. Async (T2 user request, estimated medium each, pushed back 3, reason: Facet waves first): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming`, `program-jobs`; debugger: `socket-probe`, `debug-keys` (estimated small), `debug-breakpoints`, `debug-channel`, `debug-session` (estimated large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
9. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 6, reason: after the UI track); `git-panel`, `lint-panel` (T2, estimated large); `claude-bridge`, `claude-workflow` (T2 ideas, estimated large).
10. Containers (T2 user request, estimated medium each, after the Facet waves): `dockerfile-support` (estimated small), `containers-panel`, `containers-logs`, the rest as the notes of 2026-11-21 slice them.
11. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, estimated medium each).
12. `theme-tuning`, `semantic-highlight` (T5, estimated medium, estimated large); `plugin-protocol-a`, `formatting`, `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each); `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 8, reason: after the UI track); `csv-viewer` (T5, estimated large, pushed back 12, reason: after the UI track).
13. `bidi-controls` (T3 Lows, estimated small, pushed back 13, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, estimated small).

## Decisions

- Security first (T0): none; sprint-29 review High 0, Medium 0; no periodic finding at confidence 8 or above unfixed.
- Split (T2): ui-groups-b's 4 headings are 3 independently tested parts (status bar snapshots, the message group, a pty smoke case) over 3 map areas; recent-files-persist note 6: 4 areas, 11 code files, 2.7x its output budget. ui-groups-b keeps the 2 status bar headings, `ui-groups-c` (Pool 1) the other 2.
- Estimated medium (T2): last 10 feature rows 859,472 to 1,213,986 total tokens; window-surfaces 859,472, prompt-in-float 895,682, recent-files-persist 927,740 under 1.2M, no size-up.
- Not critical (T2): no path of rules a to d; `ansi_terminal.rb` read, not edited.
- Placed (T1): recent-files-persist notes 6, 7 as backlog-lane `split-at-placement` and `nonblocking-round` entries in this plan's backlog.md; that lane's queue untouched.
