# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 21

The user-approved exception (2026-11-19, the finder-match-strict brief): `finder-grep-c` and `finder-match-strict` (Pool 1 at f2c6f46, the user's order) run outside the 3.

1. `message-styling` (T2 user request, estimated medium, Facet wave 2, parts 4 and 5 of `cursor-and-messages`): the command line and message row miss the Facet styling. Command line: prompt DIM, text FG, pending keys and the match count DIM at the right (`carat/adapters/frame_presenter.rb:1324`, `:1341`). Messages: an error paints its whole line MESSAGE_ERROR (`:1388`, `:1358`); wanted error RED glyph, bold RED code, FG text; warning YELLOW glyph, FG text; info DIM; `-- More --` bold BLUE; `-- INSERT --` dropped from the message row (`:1390`, the pill shows the mode); Question and MoreMsg painted (`carat/domain/highlight.rb:42`). This makes the squash body of #223 true. Accepted when frame rows show each in carat-dark and carat-light and NO_COLOR keeps the attributes. Out: the multi-line band, diagnostic text, `ui-groups`. Backlog: "### The squash body of #223 claims styling its diff lacks".

## Pool

1. `grep-long-files` (T2 user request, estimated medium): 4 files of this tree are searched only to FILE_ROWS 1000 (`carat/plugins/finder/grep.rb:24`); a host request, API minor bump: "### Grep files are searched only to their first 1000 lines".
2. `vim-case-operators` (T2 user request, estimated medium, pushed back 4, reason: the user's Sprint 21 picks): g~ gu gU.
3. `background-detect` (T2 user request, estimated medium, pushed back 3, reason: the user's picks): OSC 11 at startup (`carat/drivers/ansi_terminal.rb`); carat-light on a light reply, no wait.
4. `search-count` (T2 user request, estimated medium, pushed back 3, same reason): `[3/12]` at the right after `/` and `n` (`carat/domain/search_budget.rb`, `carat/use_cases/search/find_match.rb`).
5. `ui-groups` (T2 user request, estimated small, pushed back 3, same reason): 7 groups (`carat/domain/highlight.rb:150`), EndOfBuffer and Question painted (`themes.rb:118`, `:125`); "### facet-palette dropped the brief's PANEL_DIM".
6. `vim-folds-d` (T2 user request, estimated medium): `:fold`, `:foldopen`, `:foldclose`.
7. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: no location for its gaps): "### MarkdownText.parse runs the marker scan twice per line".
8. Facet wave 2 rest (T2 user request, estimated medium each): `status-winbar-tabs`, `listchars-folds`.
9. Facet wave 3 (T2 user request, estimated medium each, after `bench-scenarios`): `border-vocabulary`, `window-surfaces` (sidebar #111319), `prompt-in-float`, `dim-backdrop`, `float-polish`.
10. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens`, `finder-refined`, `key-hints-dock`, `explorer-rows` (width 36, from 30 at `config/default.caratrc:766`, `carat/plugins/explorer/plugin.rb:66`).
11. Async work (T2 user request, estimated medium each, about one a sprint, after `spinel-bump`; plan `tmp/briefs/async/study.md`): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` ("### Grep picker reads every file synchronously when it opens", "### The grep picker reads every listed file synchronously on the editor (sprint-20 review security Low (3), plugin.rb:186)"), `program-jobs` (before the git panel's commit).
12. Facet wave 5 (T2 user request, estimated medium each): `start-gem`, `diagnostic-text`, `explorer-git`.
13. `tree-spike`, `mermaid-spike` (T2 user request, estimated medium each, `tmp/briefs/carat-tree/study.md`, `tmp/briefs/mermaid/study.md`; `tmp/briefs/fiber/study.md` a study only).
14. `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track and the spikes).
15. `git-panel` (T2 user request, estimated large, pushed back 5, reason: the user's roadmap, after the design waves, async, carat-tree, Mermaid; split at its start).
16. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each): after `git-panel`, once the user approves its plan.
17. `lint-panel` (T2 user request, estimated large, pushed back 2, reason: the user's roadmap): `:grep :make :cnext :copen`.
18. `vim-increment` (T2 user request, estimated small): `<C-a>`, `<C-x>`.
19. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
20. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no visible effect; after `spinel-bump`): `json.rb:72`.
21. `plugin-protocol-a`, `formatting` (T5, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
22. `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
23. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track).
24. `csv-viewer` (T5, estimated large, pushed back 10, same reason).
25. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first); `project-config-guards` (T3, estimated medium, pushed back 23, same reason): `config.rb:221`, `rc_config_gateway.rb:70`, `file_requests.rb:143`.
26. `insert-copy` (T4, estimated small).

## Decisions

- Delivering (T2 user request, pushed back 5): `vim-folds-c`, Sprint 21 item 1 at 3830d72, removed; the main session's brief.
- Estimate large (T2): base medium from the fold rows vim-folds-a 1,678,269, vim-folds-b 904,033, vim-folds-windows 1,095,387; one up, the last two lane runs over 1,200,000 (finder-grep-preview 2,075,638 in 110 min, finder-match-strict 1,971,222 in 103 min).
- Size check (T2): two behaviors of one fold family (`zR` `zM` levels, `zj` `zk` `[z` `]z` motions) and one test of existing code (`buffer_list.rb:369`), inside the user's roadmap: no split; on a stop, the motions go to the pool as `vim-folds-motions`.
- Critical (T2, rule e): estimated large, `carat/use_cases/actions/fold_handler.rb`; no rule d path (`buffer_list.rb` is not `buffer.rb`).
- Security first (T0): none; neither pending run state (delivery-guards-c, finder-grep-preview) holds a periodic finding.
- Delivered (T2): `finder-grep-preview` merged 3830d72fbe80, rework 2, 2,075,638 total in 110 min, over medium (overruns 7, 8, 9, 12: 409,157 output of 200,000).
- Notes (T1): finder-grep-preview retros 13 to 15 are pipeline, the backlog lane's, sent to the findings file, 14 merged into `check-pass-budget-flag`; quality 1 to 6, 10, 11 handled; 16 is merge-body-sections', the backlog lane's.
- Pending (T1): delivery-guards-c, merged e4fb38076e90, notes 1 to 7 are the backlog lane's (`check-runner-safety` plans them); its note 5 (size-up by unrelated rows) applies to this large.
- Sprint (T2): Sprint 21 keeps `message-styling` and the exception's two outside the 3; no item moved, 0 push-backs added.
- Merge gate (T1): 0 `tools/rules.sh` edits.
