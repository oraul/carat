# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 21

The user-approved exception (2026-11-19, the finder-match-strict brief): `finder-grep-c` and `finder-match-strict` (Pool 1 at f2c6f46, the user's order) run outside the 3.

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

- Delivering (T2 user request): `message-styling`, Sprint 21 item 1 at 1b12495, removed; the main session's brief, the last of the sprint's three.
- Locations (T2): at 1b12495 the message row is `paint_message` (`carat/adapters/frame_presenter.rb:1392`): prompt `:1394` NORMAL, error `:1401` MESSAGE_ERROR on the whole line, `-- INSERT --` `:1404`, pending keys `:1418` NORMAL; `:1371` is the multi-line band, out; `:1324` is a layout separator, not the command line.
- Scope (T2): 0 producers at 1b12495 for `-- More --`, a match count (`search-count`, Pool 4), or a warning or info message (only `message_error`); accepted as theme rows for those groups unless the user asks for producers.
- Estimate medium (T2): Facet rows cursor-and-messages 1,164,314 in 99 min, background-default 1,095,842, match-paren 1,005,270; no size up, 1 of the last two lane runs over (finder-grep-preview 2,075,638 of 1,200,000; vim-folds-c 1,326,711 of large 2,500,000).
- Size check (T2): 2 parts (command line, message row), 2 map areas (adapters frame, domain highlight and themes): no split; on a stop, the command line goes to the pool as `cmdline-styling`.
- Critical (T2): none; `frame_presenter.rb`, `highlight.rb`, `themes.rb` are no rule a to d path, and the estimate is medium.
- Security first (T0): none; 0 `review.periodic` in the pending run states delivery-guards-c and vim-folds-c.
- Delivered (T2): `vim-folds-c` merged 1b12495bdd41, large, rework 1, 1,326,711 total in 69 min, within budget.
- Placed (T1): vim-folds-c retros 3 (advisory-only round counted as rework, 71,761 output) and 4 (merge 32,655 output, green first CI) are the backlog lane's, to the findings file, near-same to `rework-review-repeat` and `merge-output-cap`; note 5 is finder-grep-preview's overrun, placed before; quality 1, 2 handled.
- Pending (T1): delivery-guards-c notes 5 to 7 stay the backlog lane's, `check-runner-safety` plans them.
- Sprint (T2): Sprint 21 holds its 3 features delivered after this; no item moved, 0 push-backs added.
- Merge gate (T1): 0 `tools/rules.sh` edits.
