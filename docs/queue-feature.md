# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 20

The user-approved exception: `finder-grep` (T2 user request, estimated medium, beyond the sprint, 2026-11-19 "Can you priorize it?"): delivered now from Pool 23.

1. `vim-folds-c` (T2 user request, estimated medium, Sprint 20 by the user's request, pushed back 3, reason: the user's `finder-grep` first): `zR`, `zM`, `zj`, `zk`, `[z`, `]z` are missing (`carat/use_cases/actions/fold_handler.rb:43`). Accepted when each has a `docs/compatibility.md` row, a `config/default.caratrc` binding in every mode its motion needs, and a table-driven test row matching Vim. Backlog: none.

## Pool

1. `vim-case-operators` (T2 user request, estimated medium, pushed back 3, reason: the user's Sprint 20 picks; Sprint 21 after `vim-folds-c`): g~ gu gU.
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
23. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track).
24. `csv-viewer` (T5, estimated large, pushed back 10, same reason).
25. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first); `project-config-guards` (T3, estimated medium, pushed back 23, same reason): `config.rb:221`, `rc_config_gateway.rb:70`, `file_requests.rb:143` (sweep Low (4)).
26. `insert-copy` (T4, estimated small).

## Decisions

- Delivered (T2 user request, "Can you priorize it?"): `finder-grep` leaves Pool 23 (T5, pushed back 6).
- Sprint count (T1): `closing-loop` spent `SPRINT_EXCEPTIONS` 1: sprint-20 is 5 of 6, the next merge closes it, `vim-folds-c` opens Sprint 21.
- Estimate medium (T2): match-paren 1,005,270 / 69 min, cursor-and-messages 1,164,314 / 99 min, both under 1,200,000, no size up.
- No split (T2, size rule): 1 code area (`carat/plugins/finder/`), one picker, one acceptance.
- Host limit (T2): `read_file` gives at most 1000 rows of a file up to 256 KiB (`carat/plugin_api.rb:659`): the proposal states it, or stop.
- Security first (T0), none open: no pending `review.periodic-*`; sprint-19 periodic security high=0 medium=0 low=1.
- Retro (T1): `closing-loop` notes 10, 11 to `backlog.md` (backlog queue out of lane); 1 to 9 handled.
- Merge gate (T1): the brief edits no `tools/rules.sh`.
