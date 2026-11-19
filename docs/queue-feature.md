# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 21

The user-approved exception (2026-11-19, the finder-match-strict brief): `finder-grep-c` and `finder-match-strict` (Pool 1 at f2c6f46, the user's order) run outside the 3.

1. `vim-folds-c` (T2 user request, estimated medium, pushed back 5, reason: the user's order, `finder-grep-preview` first): `zR`, `zM`, `zj`, `zk`, `[z`, `]z` are missing (`carat/use_cases/actions/fold_handler.rb:43`); and the single-window branch of `close_window` (`carat/domain/buffer_list.rb:369`) drops a kept slot's folds untested (sprint-20 review quality). Accepted when each key has a `docs/compatibility.md` row, a `config/default.caratrc` binding in every mode its motion needs, and a table-driven row matching Vim, and a test runs `:q` on a second tab page's only window beside a hidden slot window with a fold and sees its fold list shrink. Backlog: none.
2. `message-styling` (T2 user request, estimated medium, Facet wave 2, parts 4 and 5 of `cursor-and-messages`): the command line and message row miss the Facet styling. Command line: prompt DIM, text FG, pending keys and the match count DIM at the right (`carat/adapters/frame_presenter.rb:1324`, `:1341`). Messages: an error paints its whole line MESSAGE_ERROR (`:1388`, `:1358`); wanted error RED glyph, bold RED code, FG text; warning YELLOW glyph, FG text; info DIM; `-- More --` bold BLUE; `-- INSERT --` dropped from the message row (`:1390`, the pill shows the mode); Question and MoreMsg painted (`carat/domain/highlight.rb:42`). This makes the squash body of #223 true. Accepted when frame rows show each in carat-dark and carat-light and NO_COLOR keeps the attributes. Out: the multi-line band, diagnostic text, `ui-groups`. Backlog: "### The squash body of #223 claims styling its diff lacks".

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

- Delivering (T2 user request, the brief of 2026-11-19): `finder-grep-preview`, Pool 1 at a2a0f80, removed; the user's order: after `finder-match-strict`, before `vim-folds-c`.
- Estimate medium (T2): 8 of the last 10 feature rows medium; finder-grep-b, the nearest (one area, `carat/plugins/finder/`), 997,989 in 82 min.
- No size up (T2): of the last two only finder-match-strict went over (1,971,222 of 1,200,000, 103 min); finder-grep-c 1,862,327 of large's 2,500,000.
- Size check (T2): one map area, one behavior (layout, centred window, mark, safe text): no split; on a stop, the centred safe preview first, the follow and clamp rows next.
- Critical (T2): none of rules a to e; `carat/plugins/finder/` is outside rule d and no host request is added.
- Security first (T0): none; no pending run state holds a periodic finding; open Mediums at confidence 6 and 4, below 8.
- Delivered (T2, the exception): `finder-match-strict` merged a85da7940c56, rework 2, 1,971,222 total, over medium (notes 9, 10, 12).
- Notes (T1): finder-match-strict retros 13 to 15 are backlog-lane, sent to the findings file, 14 merged into `advisory-findings-auto`, 15 into `check-pass-budget-flag`; quality 1 to 12 handled.
- Pending (T1): merge-body-sections, merged a2a0f80dbcfa, notes 5 to 8 are the backlog lane's.
- Aging (T2): `vim-folds-c` pushed back 5, next after this delivery.
- Merge gate (T1): 0 `tools/rules.sh` edits.
