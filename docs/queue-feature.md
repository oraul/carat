# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 22

1. `vim-case-operators` (T2 user request, estimated medium, pushed back 4, reason: the user's Sprint 21 picks): g~, gu, gU with motions, text objects, and counts, the linewise g~~ guu gUU, and ~ u U in the 5 visual modes. Where: `carat/domain/operators.rb`, keymap lines in `config/default.caratrc`, `docs/compatibility.md`, `docs/actions.md`. Accepted when a table-driven test per key matches Neovim, multibyte letters included, `.` repeats it and one `u` undoes it, with compatibility and actions rows. Backlog: none.
2. `background-detect` (T2 user request, estimated medium, pushed back 3, reason: the user's picks): a light terminal starts on the dark theme. Where: startup in `carat/drivers/ansi_terminal.rb`, the theme option in `config/default.caratrc`. Fix outline: ask OSC 11 at startup, choose carat-light on a light reply, never wait; the reply is untrusted input, parsed bounded. Accepted when tests with a dark, a light, a malformed, and no reply pick the theme, a configured theme wins, and the first frame waits for no reply. Backlog: none.

## Pool

1. `finder-path-safe` (T2 user request, split from grep-long-files, security Low (5), Low (3), estimated medium, critical a carat/plugins/finder/plugin.rb): Where: `carat/plugins/finder/plugin.rb:333` (file finder rows and preview title show the listed path raw, sprint-21 review security Low (5)), `grep.rb` safe (grep rows pass other bidi and zero-width code points, Low (3)), `plugin.rb:394` (a pick into a modified buffer can land on another line). Fix outline: one sanitizer for both pickers. Accepted when a path with U+202E and a control byte shows escaped in the row and title and opens raw, a grep row shows each format code point escaped, and a pick into a modified buffer lands on its matched line. Backlog: "### The file finder shows paths as the file lists them", "### File finder rows and preview title show the listed path unsanitized", "### Grep.safe passes bidi and zero-width format code points into rows", "### Grep rows still pass the other invisible format code points".
2. `search-count` (T2 user request, estimated medium, pushed back 3, reason: the user's order puts it fourth): `[3/12]` at the right after `/` and `n` (`carat/domain/search_budget.rb`, `carat/use_cases/search/find_match.rb`); "### Nothing produces a warning or information level, a -- More -- pager, or a match count".
3. `ui-groups` (T2 user request, estimated small, pushed back 3, reason: the user's order puts it fifth): 7 groups (`carat/domain/highlight.rb:150`), EndOfBuffer and Question (`themes.rb:118`, `:125`); "### facet-palette dropped the brief's PANEL_DIM", "### The message row still shows the visual mode indicators the pill already shows" (`frame_presenter.rb:1431`).
4. `vim-folds-d` (T2 user request, estimated medium): `:fold`, `:foldopen`, `:foldclose`.
5. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: no location for its gaps): "### MarkdownText.parse runs the marker scan twice per line".
6. Facet wave 2 rest (T2 user request, estimated medium each): `status-winbar-tabs`, `listchars-folds`.
7. Facet wave 3 (T2 user request, estimated medium each): `border-vocabulary`, `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`.
8. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens`, `finder-refined`, `key-hints-dock`, `explorer-rows` (width 36, from 30 at `config/default.caratrc:766`, `carat/plugins/explorer/plugin.rb:66`).
9. Async work (T2 user request, estimated medium each, about one a sprint; plan `tmp/briefs/async/study.md`): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` ("### Grep picker reads every file synchronously when it opens", "### The grep picker reads every listed file synchronously on the editor (sprint-20 review security Low (3), plugin.rb:186)"), `program-jobs`.
10. Facet wave 5 (T2 user request, estimated medium each): `start-gem`, `diagnostic-text`, `explorer-git`.
11. `tree-spike`, `mermaid-spike` (T2 user request, estimated medium each, `tmp/briefs/carat-tree/study.md`, `tmp/briefs/mermaid/study.md`; `tmp/briefs/fiber/study.md` a study only).
12. `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the spikes).
13. `git-panel` (T2 user request, estimated large, pushed back 5, reason: the user's roadmap, after async and the spikes; split at its start).
14. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each): after `git-panel`, once the user approves its plan.
15. `lint-panel` (T2 user request, estimated large, pushed back 2, reason: the user's roadmap): `:grep :make :cnext :copen`.
16. `vim-increment` (T2 user request, estimated small): `<C-a>`, `<C-x>`.
17. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
18. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no visible effect): `json.rb:72`.
19. `plugin-protocol-a`, `formatting` (T5, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
20. `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
21. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track).
22. `csv-viewer` (T5, estimated large, pushed back 10, same reason).
23. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first); `project-config-guards` (T3, estimated medium, pushed back 23, same reason): `config.rb:221`, `rc_config_gateway.rb:70`, `file_requests.rb:143`.
24. `insert-copy` (T4, estimated small).

## Decisions

- Sprint (T2 user request): 3 features, 3 backlog; Sprint 22's features are the user's order of 2026-11-19: grep-long-files (delivering), vim-case-operators, background-detect.
- Estimate large (T2): finder rows 997,989 to 2,075,638, 4 of the last 5 over 1,200,000; of the last two rows 1 over budget, so no size up; critical d for the host request in `carat/plugin_api.rb`.
- Split (T2): 3 acceptance checks plus `plugin.rb:394` in 2 map areas; grep-long-files keeps the long files, the preview's end, and the grep scenario's figure, the sanitizer and the pick line go to Pool 1 `finder-path-safe`.
- Recorded (T1): sprint-21-records retro notes 8 and 9 (rework 2, advisories_left 4 for 2 distinct) go to the findings file while the backlog lane is another delivery's; note 8 is near `rework-review-repeat`.
- Overrun (T1): sprint-21-records small, 983,348 total in 16 min, over 500,000.
- Security first (T0): none; 0 High or Medium at confidence 8 or above in sprint-21-records (high=0 medium=0) or the pending runs.
