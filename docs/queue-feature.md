# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 20

1. `cursor-and-messages` (T2 user request, estimated small, Facet wave 2, rolled over from Sprint 19 by the user's decision): the Facet plan's cursor and message-line styling; no source names its files, its first step draws them. Accepted when frame rows show the plan's cursor and message styling in both themes. Backlog: none.
2. `vim-folds-windows` (T2 user request, estimated medium, Sprint 20 by the user's request, pushed back 2): folds and windows disagree with Vim at four places (`carat/use_cases/arrange_view.rb:60`, `carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`, `carat/domain/buffer.rb:648`). Fix outline: the contributor reads the four places and matches Vim. Accepted when `zfjiX` edits inside the fold as Vim does and `zfj<C-w>s<C-w>c` leaves 1 fold list, each a table row. Backlog: none (no open heading names its four locations).
3. `vim-folds-c` (T2 user request, estimated medium, Sprint 20 by the user's request, pushed back 2): `zR`, `zM`, `zj`, `zk`, `[z`, `]z` are missing (`carat/use_cases/actions/fold_handler.rb:43`). Accepted when each has a `docs/compatibility.md` row, a `config/default.caratrc` binding in every mode its motion needs, and a table-driven test row matching Vim. Backlog: none.

## Pool

1. `vim-case-operators` (T2 user request, estimated medium, pushed back 3, reason: the user's roll-over of `cursor-and-messages` took its Sprint 20 slot; first in Sprint 21): g~ gu gU.
2. `background-detect` (T2 user request, estimated medium, Facet wave 1 item 5b, pushed back 2): OSC 11 at startup (`carat/drivers/ansi_terminal.rb`); carat-light on a light reply, no wait.
3. `search-count` (T2 user request, estimated medium, Facet wave 1 item 4b, pushed back 2): `[3/12]` at the right after `/` and `n` (`carat/domain/search_budget.rb`, `carat/use_cases/search/find_match.rb`).
4. `ui-groups` (T2 user request, estimated small, Facet wave 1 item 2, pushed back 2): 7 groups (`carat/domain/highlight.rb:150`), EndOfBuffer and Question painted (`themes.rb:118`, `:125`); "### facet-palette dropped the brief's PANEL_DIM".
5. `vim-folds-d` (T2 user request, estimated medium): `:fold`, `:foldopen`, `:foldclose`.
6. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: no location for its gaps): "### MarkdownText.parse runs the marker scan twice per line".
7. Facet wave 2 rest (T2 user request, estimated medium each): `status-winbar-tabs`, `listchars-folds`.
8. Facet wave 3 (T2 user request, estimated medium each, after `bench-scenarios`): `border-vocabulary`, `window-surfaces` (dark sidebar #111319), `prompt-in-float`, `dim-backdrop`, `float-polish`.
9. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens`, `finder-refined`, `key-hints-dock`, `explorer-rows` (explorer width 36, from 30 at `config/default.caratrc:766`, `carat/plugins/explorer/plugin.rb:66`).
10. Facet wave 5 (T2 user request, estimated medium each): `start-gem`, `diagnostic-text`, `explorer-git`.
11. Async work (T2 user request, estimated medium each, about one a sprint, after `spinel-bump` in the backlog lane; plan `tmp/briefs/async/study.md`): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming`, `program-jobs` (before the git panel's commit).
12. `tree-spike`, `mermaid-spike` (T2 user request, estimated medium each, first steps of `tmp/briefs/carat-tree/study.md` and `tmp/briefs/mermaid/study.md`; `tmp/briefs/fiber/study.md` a study only).
13. `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track and the spikes).
14. `git-panel` (T2 user request, estimated large, pushed back 5, reason: the user's roadmap, after the design waves, async, carat-tree, Mermaid; split at its start).
15. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each): AI after `git-panel`, only once the user approves its plan.
16. `lint-panel` (T2 user request, estimated large, pushed back 2, reason: the user's roadmap): `:grep :make :cnext :copen`.
17. `vim-increment` (T2 user request, estimated small): `<C-a>`, `<C-x>`.
18. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
19. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no visible effect): `json.rb:72`.
20. `plugin-protocol-a`, `formatting` (T5, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
21. `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
22. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track).
23. `csv-viewer` (T5, estimated large, pushed back 10, same reason).
24. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first); `project-config-guards` (T3, estimated medium, pushed back 23, same reason): `config.rb:221`, `rc_config_gateway.rb:70`, `file_requests.rb:143` (sweep Low (4)).
25. `insert-copy` (T4, estimated small).

## Decisions

- Sprint 20, 3 features, 3 backlog (T2, the user's decisions of 2026-11-18/19, match-paren note 13): `cursor-and-messages` rolled over first, then `vim-folds-windows` and `vim-folds-c`; `vim-case-operators` moved to Pool 1.
- Security first (T0), none open: sprint-19 review's one security finding is Low (5) at `deliver-change.js:952`; sprint-18 Medium (9) fixed by b5b0aec (#214).
- Async plan (T2, the user's request, note 13 item 3): 7 items in Pool 11 after the design waves' current items, then the spikes in Pool 12, Mermaid, git panel, AI.
- `match-paren` closed (T2): e6d4010 (#220), rework 2, first quality 0; retro 10 to backlog Pool `pr-testing-truth`, retro 11 to `rework-review-repeat`, overrun 12 (1,207,861 of 1,200,000) already at backlog Pool `check-pass-budget-flag`.
- Trial (T1): match-paren is delivery 1 of 6 on the mid tier (#219); the verdict waits for 6, baseline quality first pass 98/176.
- Sprint 20 is even (T1, `review_due`): the whole-tree review runs at its end.
