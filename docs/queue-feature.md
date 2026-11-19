# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 20

1. `vim-folds-windows` (T2 user request, estimated medium, Sprint 20 by the user's request, pushed back 2): folds and windows disagree with Vim at four places (`carat/use_cases/arrange_view.rb:60`, `carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`, `carat/domain/buffer.rb:648`). Fix outline: the contributor reads the four places and matches Vim. Accepted when `zfjiX` edits inside the fold as Vim does and `zfj<C-w>s<C-w>c` leaves 1 fold list, each a table row. Backlog: none (no open heading names its four locations).
2. `vim-folds-c` (T2 user request, estimated medium, Sprint 20 by the user's request, pushed back 2): `zR`, `zM`, `zj`, `zk`, `[z`, `]z` are missing (`carat/use_cases/actions/fold_handler.rb:43`). Accepted when each has a `docs/compatibility.md` row, a `config/default.caratrc` binding in every mode its motion needs, and a table-driven test row matching Vim. Backlog: none.

## Pool

1. `vim-case-operators` (T2 user request, estimated medium, pushed back 3, reason: the user's roll-over of `cursor-and-messages` took its Sprint 20 slot; first in Sprint 21): g~ gu gU.
2. `message-styling` (T2 user request, estimated medium, Facet wave 2, split from `cursor-and-messages` by the size rule, parts 4 and 5 of its 5): the command line and message row miss the Facet plan's styling. Command line: prompt DIM, text FG, pending keys and the match count DIM at the right end (`carat/adapters/frame_presenter.rb:1324`, `:1341`). Messages: today an error paints its whole line MESSAGE_ERROR (`:1388`, `:1358`); wanted error RED glyph, bold RED code, FG text; warning YELLOW glyph, FG text; info DIM; `-- More --` bold BLUE; `-- INSERT --` dropped from the message row (`:1390`, the pill shows the mode; screen-rendering spec text); Question and MoreMsg painted (`carat/domain/highlight.rb:42`). Accepted when frame rows show each in carat-dark and carat-light and NO_COLOR keeps the attributes. Out: the multi-line band (wave 3), diagnostic text (wave 5), `ui-groups`. Backlog: none.
3. `background-detect` (T2 user request, estimated medium, Facet wave 1 item 5b, pushed back 2): OSC 11 at startup (`carat/drivers/ansi_terminal.rb`); carat-light on a light reply, no wait.
4. `search-count` (T2 user request, estimated medium, Facet wave 1 item 4b, pushed back 2): `[3/12]` at the right after `/` and `n` (`carat/domain/search_budget.rb`, `carat/use_cases/search/find_match.rb`).
5. `ui-groups` (T2 user request, estimated small, Facet wave 1 item 2, pushed back 2): 7 groups (`carat/domain/highlight.rb:150`), EndOfBuffer and Question painted (`themes.rb:118`, `:125`); "### facet-palette dropped the brief's PANEL_DIM".
6. `vim-folds-d` (T2 user request, estimated medium): `:fold`, `:foldopen`, `:foldclose`.
7. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: no location for its gaps): "### MarkdownText.parse runs the marker scan twice per line".
8. Facet wave 2 rest (T2 user request, estimated medium each): `status-winbar-tabs`, `listchars-folds`.
9. Facet wave 3 (T2 user request, estimated medium each, after `bench-scenarios`): `border-vocabulary`, `window-surfaces` (dark sidebar #111319), `prompt-in-float`, `dim-backdrop`, `float-polish`.
10. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens`, `finder-refined`, `key-hints-dock`, `explorer-rows` (explorer width 36, from 30 at `config/default.caratrc:766`, `carat/plugins/explorer/plugin.rb:66`).
11. Facet wave 5 (T2 user request, estimated medium each): `start-gem`, `diagnostic-text`, `explorer-git`.
12. Async work (T2 user request, estimated medium each, about one a sprint, after `spinel-bump` in the backlog lane; plan `tmp/briefs/async/study.md`): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming`, `program-jobs` (before the git panel's commit).
13. `tree-spike`, `mermaid-spike` (T2 user request, estimated medium each, first steps of `tmp/briefs/carat-tree/study.md` and `tmp/briefs/mermaid/study.md`; `tmp/briefs/fiber/study.md` a study only).
14. `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track and the spikes).
15. `git-panel` (T2 user request, estimated large, pushed back 5, reason: the user's roadmap, after the design waves, async, carat-tree, Mermaid; split at its start).
16. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each): AI after `git-panel`, only once the user approves its plan.
17. `lint-panel` (T2 user request, estimated large, pushed back 2, reason: the user's roadmap): `:grep :make :cnext :copen`.
18. `vim-increment` (T2 user request, estimated small): `<C-a>`, `<C-x>`.
19. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
20. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no visible effect): `json.rb:72`.
21. `plugin-protocol-a`, `formatting` (T5, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
22. `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
23. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track).
24. `csv-viewer` (T5, estimated large, pushed back 10, same reason).
25. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first); `project-config-guards` (T3, estimated medium, pushed back 23, same reason): `config.rb:221`, `rc_config_gateway.rb:70`, `file_requests.rb:143` (sweep Low (4)).
26. `insert-copy` (T4, estimated small).

## Decisions

- Split (T2, size rule, three or more parts): the brief holds 5 independently testable parts; `cursor-and-messages` delivers parts 1 to 3 (cursor line across the gutter, cursor and relative numbers, steady shapes), parts 4 and 5 queued as `message-styling` in Pool 2.
- Estimate medium (T2): the Facet rows guide-colors 922,993, facet-palette 1,273,459, background-default 1,095,842, gutter-signcolumn 1,207,861, match-paren 1,005,270 total tokens (61 to 95 minutes) all exceed small (500k, 25 minutes); only gutter-signcolumn of the last two over, no size up.
- Sprint 20, 3 features (T2, the user's decisions, match-paren note 13): `cursor-and-messages` delivered, `vim-folds-windows` and `vim-folds-c` stay; `message-styling` waits behind `vim-case-operators` (pushed back 3, first in Sprint 21).
- Security first (T0), none open: no pending High or Medium at confidence 8 or above; sprint-19 review's one finding Low (5) at `deliver-change.js:952`.
- Pending notes (T1): `sprint-19-records` notes 1 to 4 are quality advisories on the backlog groom, the backlog lane's, none placed here.
- Merge gate (T1): the brief edits no `tools/rules.sh`, no split for it.
