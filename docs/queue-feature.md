# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 22

Full: grep-long-files 026a6a0, vim-case-operators c2fbbb4, background-detect delivering.

## Pool

1. `background-theme` (T2 user request, split from background-detect, estimated medium): a light terminal starts on carat-dark (`config/default.caratrc:58`). Where: `carat/domain/themes.rb`, `carat/domain/config.rb`, `bin/carat.rb`. Fix outline: take the background background-detect reports, carat-light on light, redraw on the switch. Accepted when tests with a dark, a light, a malformed, and no reply pick the theme, a theme set in a `.caratrc` or by `:set` wins, and the first frame waits for no reply. Backlog: none.
2. `finder-path-safe` (T2 user request, split from grep-long-files, security Low (5), Low (3), estimated medium, critical a carat/plugins/finder/plugin.rb): Where: `carat/plugins/finder/plugin.rb:333` (file finder rows and preview title show the listed path raw, sprint-21 review security Low (5)), `grep.rb` safe (grep rows pass other bidi and zero-width code points, Low (3)), `plugin.rb:394` (a pick into a modified buffer can land on another line). Fix outline: one sanitizer for both pickers. Accepted when a path with U+202E and a control byte shows escaped in the row and title and opens raw, a grep row shows each format code point escaped, and a pick into a modified buffer lands on its matched line. Backlog: "### The file finder shows paths as the file lists them", "### File finder rows and preview title show the listed path unsanitized", "### Grep.safe passes bidi and zero-width format code points into rows", "### Grep rows still pass the other invisible format code points".
3. `search-count` (T2 user request, estimated medium, pushed back 3, reason: the user's order puts it fourth): `[3/12]` at the right after `/` and `n` (`carat/domain/search_budget.rb`, `carat/use_cases/search/find_match.rb`); "### Nothing produces a warning or information level, a -- More -- pager, or a match count".
4. `ui-groups` (T2 user request, estimated small, pushed back 3, reason: the user's order puts it fifth): 7 groups (`carat/domain/highlight.rb:150`), EndOfBuffer and Question (`themes.rb:118`, `:125`); "### facet-palette dropped the brief's PANEL_DIM", "### The message row still shows the visual mode indicators the pill already shows" (`frame_presenter.rb:1431`).
5. `vim-folds-d` (T2 user request, estimated medium): `:fold`, `:foldopen`, `:foldclose`.
6. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: no location for its gaps): "### MarkdownText.parse runs the marker scan twice per line".
7. Facet wave 2 rest (T2 user request, estimated medium each): `status-winbar-tabs`, `listchars-folds`.
8. Facet wave 3 (T2 user request, estimated medium each): `border-vocabulary`, `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`.
9. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens`, `finder-refined`, `key-hints-dock`, `explorer-rows` (width 36, from 30 at `config/default.caratrc:766`, `carat/plugins/explorer/plugin.rb:66`).
10. Async work (T2 user request, estimated medium each, about one a sprint; plan `tmp/briefs/async/study.md`): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` ("### Grep picker reads every file synchronously when it opens", "### The grep picker reads every listed file synchronously on the editor (sprint-20 review security Low (3), plugin.rb:186)"), `program-jobs`.
11. Facet wave 5 (T2 user request, estimated medium each): `start-gem`, `diagnostic-text`, `explorer-git`.
12. `tree-spike`, `mermaid-spike` (T2 user request, estimated medium each, `tmp/briefs/carat-tree/study.md`, `tmp/briefs/mermaid/study.md`; `tmp/briefs/fiber/study.md` a study only).
13. `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the spikes).
14. `git-panel` (T2 user request, estimated large, pushed back 5, reason: the user's roadmap, after async and the spikes; split at its start).
15. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each): after `git-panel`, once the user approves its plan.
16. `lint-panel` (T2 user request, estimated large, pushed back 2, reason: the user's roadmap): `:grep :make :cnext :copen`.
17. `vim-increment` (T2 user request, estimated small): `<C-a>`, `<C-x>`.
18. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
19. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no visible effect): `json.rb:72`.
20. `plugin-protocol-a`, `formatting` (T5, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
21. `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
22. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track).
23. `csv-viewer` (T5, estimated large, pushed back 10, same reason).
24. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first); `project-config-guards` (T3, estimated medium, pushed back 23, same reason): `config.rb:221`, `rc_config_gateway.rb:70`, `file_requests.rb:143`.
25. `insert-copy` (T4, estimated small).

## Decisions

- Security first (T0): none; pr-trust-lows high=0 medium=0 low=2, vim-case-operators high=0 medium=0, no periodic finding pending.
- Split (T2): background-detect spans 5 map areas (17, 5, 14, 3, 4), over the 3-area rule: it sends OSC 11 and parses the reply bounded (17, 5); `background-theme` picks the theme (14, 3, 4), Pool 1 as Sprint 22 holds 3 features.
- Size (T2): medium; 4 of the last 7 medium rows over 1.2M (1,470,193 to 2,075,638); 1 of the last two rows over budget, no size up.
- Critical (T2): d carat/drivers/ansi_terminal.rb, the terminal's reply is untrusted input.
- Already met (T2): none; no OSC 11 query or parse at c2fbbb4, tracked, clean tree.
- Overrun (T1): vim-case-operators small at 2,564,423 total, 568,067 output, 190 min (notes 13 to 18).
- Recorded (T1): vim-case-operators retro 19, 20, 21 and pr-trust-lows retro 7, 8 go to the findings file, retro 20 merged with retro 7 (bench); pr-trust-lows retro 6 is recorded already.
- Dropped (T1): pr-trust-lows note 4 (self-check-mismatch, the workflow escalates) and vim-case-operators note 22 (pr-text-blocked, fixed in its run).
