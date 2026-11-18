# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 19

1. `match-paren` (T2 user request, estimated medium, Facet wave 2): MatchParen has a theme row (`carat/domain/themes.rb:126`) no frame paints: the bracket matching the cursor's, shown by Neovim, is never shown. Fix outline: paint the pair in view, under a search budget. Accepted when frame rows show both brackets of `(`, `[`, `{` in MatchParen with the cursor on either, none for an unmatched or off-screen pair, and the `lh` bench held. Backlog: none.
2. `cursor-and-messages` (T2 user request, estimated small, Facet wave 2): the Facet plan's cursor and message-line styling; no source names its files, its first step draws them. Accepted when frame rows show the plan's cursor and message styling in both themes. Backlog: none.

## Pool

1. `background-detect` (T2 user request, estimated medium, Facet wave 1 item 5b, pushed back 1): OSC 11 at startup (`carat/drivers/ansi_terminal.rb`); carat-light on a light reply, no wait.
2. `search-count` (T2 user request, estimated medium, Facet wave 1 item 4b, pushed back 1): `[3/12]` at the right after `/` and `n` (`carat/domain/search_budget.rb`, `carat/use_cases/search/find_match.rb`).
3. `ui-groups` (T2 user request, estimated small, Facet wave 1 item 2, pushed back 1): 7 groups (`carat/domain/highlight.rb:150`), EndOfBuffer and Question painted (`themes.rb:118`, `:125`); "### facet-palette dropped the brief's PANEL_DIM".
4. `vim-folds-windows` (T2 user request, estimated medium, Sprint 20 by the user's request, pushed back 2): `arrange_view.rb:60`, `layout.rb:229`, `buffer_list.rb:370`, `buffer.rb:648`; accepted by `zfjiX`, 1 fold list after `zfj<C-w>s<C-w>c`; 5 vim-folds-b headings.
5. `vim-folds-c` (T2 user request, estimated medium, Sprint 20 by the user's request, pushed back 2): zR zM zj zk [z ]z (`fold_handler.rb:43`).
6. `vim-case-operators` (T2 user request, estimated medium, Sprint 20 by the user's request, pushed back 2): g~ gu gU.
7. `vim-folds-d` (T2 user request, estimated medium): `:fold`, `:foldopen`, `:foldclose`.
8. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: no location for its gaps): "### MarkdownText.parse runs the marker scan twice per line".
9. Facet wave 2 rest (T2 user request, estimated medium each): `status-winbar-tabs`, `listchars-folds`.
10. Facet wave 3 (T2 user request, estimated medium each, after `bench-scenarios`): `border-vocabulary`, `window-surfaces` (dark sidebar #111319), `prompt-in-float`, `dim-backdrop`, `float-polish`.
11. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens`, `finder-refined`, `key-hints-dock`, `explorer-rows` (explorer width 36, from 30 at `config/default.caratrc:766`, `carat/plugins/explorer/plugin.rb:66`).
12. Facet wave 5 (T2 user request, estimated medium each): `start-gem`, `diagnostic-text`, `explorer-git`.
13. `git-panel` (T2 user request, estimated large, pushed back 5, reason: the user's roadmap, after the design waves; split at its start).
14. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each): AI after `git-panel`, only once the user approves its plan.
15. `lint-panel` (T2 user request, estimated large, pushed back 2, reason: the user's roadmap): `:grep :make :cnext :copen`.
16. `vim-increment` (T2 user request, estimated small): `<C-a>`, `<C-x>`.
17. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
18. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no visible effect): `json.rb:72`.
19. `plugin-protocol-a`, `formatting` (T5, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
20. `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
21. `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track).
22. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, same reason).
23. `csv-viewer` (T5, estimated large, pushed back 10, same reason).
24. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first); `project-config-guards` (T3, estimated medium, pushed back 23, same reason): `config.rb:221`, `rc_config_gateway.rb:70`, `file_requests.rb:143` (sweep Low (4)).
25. `insert-copy` (T4, estimated small).

## Decisions

- `gutter-signcolumn` delivered first (T2, the user's request, Facet decision 5): Sprint 19 item 1, removed; 2 features left.
- Security first (T0): sprint-18 periodic security Medium (9) `tools/run_state.sh:449` and Low (3) `:2648` fixed by b5b0aec (#214); none open.
- Estimate medium (T2): guide-colors 922,993, background-default 1,095,842 under; facet-palette 1,273,459 over; last two not both over, no size up.
- No split (T2, size rule): one behavior, one cell, 2 locations per layer.
- sprint-18-records retros 11 to 13 (T1): backlog lane, recorded in this plan's backlog.md; 13 joins `bench-skip-no-code`.
- Pool unchanged (T2, the user's request): Facet waves, then vim items in Sprint 20.
