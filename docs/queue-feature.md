# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 21

1. `finder-grep-b` (T2 user request, estimated medium, the user's Sprint 21 item 7, critical a carat/plugins/finder/grep.rb): each key scores up to 100,000 lines and sorts every match to keep 200 (`carat/plugins/finder/grep.rb:64`, `:73`), against the nothing-waits rule, and no bench scenario measures it; the column is the first query byte, not the tightened match start (`Grep#column_at`); `Grep.safe` (`:164`) passes bidi and zero-width format code points (U+202A to U+202E, U+2066 to U+2069) from untrusted files into rows, so a row can show another path or line (sprint-20 review security Low (4)); `Grep.safe` and `Grep.utf8_size` (`:152`, `:193`) are public, used only inside Grep, and the class comment (`:14`) overruns the wrap. Fix outline: a bounded per-key cost, the span start as the column, those code points replaced. Accepted when a grep bench scenario records time per key under `make bench-budget`, and test rows show the tightened column and each code point replaced. Backlog: "### Grep column is the first query byte, not the tightened match start", "### No grep scenario in the bench".
2. `vim-folds-c` (T2 user request, estimated medium, pushed back 4, reason: the user's Sprint 21 order puts `finder-grep-b` first): `zR`, `zM`, `zj`, `zk`, `[z`, `]z` are missing (`carat/use_cases/actions/fold_handler.rb:43`); and the single-window branch of `close_window` (`carat/domain/buffer_list.rb:369`) drops a kept slot's folds untested (sprint-20 review quality). Accepted when each key has a `docs/compatibility.md` row, a `config/default.caratrc` binding in every mode its motion needs, and a table-driven row matching Vim, and a test runs `:q` on a second tab page's only window beside a hidden slot window with a fold and sees its fold list shrink. Backlog: none.
3. `message-styling` (T2 user request, estimated medium, Facet wave 2, parts 4 and 5 of `cursor-and-messages`): the command line and message row miss the Facet styling. Command line: prompt DIM, text FG, pending keys and the match count DIM at the right (`carat/adapters/frame_presenter.rb:1324`, `:1341`). Messages: an error paints its whole line MESSAGE_ERROR (`:1388`, `:1358`); wanted error RED glyph, bold RED code, FG text; warning YELLOW glyph, FG text; info DIM; `-- More --` bold BLUE; `-- INSERT --` dropped from the message row (`:1390`, the pill shows the mode); Question and MoreMsg painted (`carat/domain/highlight.rb:42`). This makes the squash body of #223 true. Accepted when frame rows show each in carat-dark and carat-light and NO_COLOR keeps the attributes. Out: the multi-line band, diagnostic text, `ui-groups`. Backlog: "### The squash body of #223 claims styling its diff lacks".

## Pool

1. `vim-case-operators` (T2 user request, estimated medium, pushed back 4, reason: the user's Sprint 21 picks): g~ gu gU.
2. `background-detect` (T2 user request, estimated medium, pushed back 3, reason: the user's picks): OSC 11 at startup (`carat/drivers/ansi_terminal.rb`); carat-light on a light reply, no wait.
3. `search-count` (T2 user request, estimated medium, pushed back 3, same reason): `[3/12]` at the right after `/` and `n` (`carat/domain/search_budget.rb`, `carat/use_cases/search/find_match.rb`).
4. `ui-groups` (T2 user request, estimated small, pushed back 3, same reason): 7 groups (`carat/domain/highlight.rb:150`), EndOfBuffer and Question painted (`themes.rb:118`, `:125`); "### facet-palette dropped the brief's PANEL_DIM".
5. `vim-folds-d` (T2 user request, estimated medium): `:fold`, `:foldopen`, `:foldclose`.
6. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: no location for its gaps): "### MarkdownText.parse runs the marker scan twice per line".
7. Facet wave 2 rest (T2 user request, estimated medium each): `status-winbar-tabs`, `listchars-folds`.
8. Facet wave 3 (T2 user request, estimated medium each, after `bench-scenarios`): `border-vocabulary`, `window-surfaces` (sidebar #111319), `prompt-in-float`, `dim-backdrop`, `float-polish`.
9. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens`, `finder-refined`, `key-hints-dock`, `explorer-rows` (width 36, from 30 at `config/default.caratrc:766`, `carat/plugins/explorer/plugin.rb:66`).
10. Async work (T2 user request, estimated medium each, about one a sprint, after `spinel-bump`; plan `tmp/briefs/async/study.md`): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` ("### Grep picker reads every file synchronously when it opens", "### The grep picker reads every listed file synchronously on the editor (sprint-20 review security Low (3), plugin.rb:186)", "### Grep files are searched only to their first 1000 lines"), `program-jobs` (before the git panel's commit).
11. Facet wave 5 (T2 user request, estimated medium each): `start-gem`, `diagnostic-text`, `explorer-git`.
12. `tree-spike`, `mermaid-spike` (T2 user request, estimated medium each, `tmp/briefs/carat-tree/study.md`, `tmp/briefs/mermaid/study.md`; `tmp/briefs/fiber/study.md` a study only).
13. `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track and the spikes).
14. `git-panel` (T2 user request, estimated large, pushed back 5, reason: the user's roadmap, after the design waves, async, carat-tree, Mermaid; split at its start).
15. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each): after `git-panel`, once the user approves its plan.
16. `lint-panel` (T2 user request, estimated large, pushed back 2, reason: the user's roadmap): `:grep :make :cnext :copen`.
17. `vim-increment` (T2 user request, estimated small): `<C-a>`, `<C-x>`.
18. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
19. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no visible effect; after `spinel-bump`): `json.rb:72`.
20. `plugin-protocol-a`, `formatting` (T5, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
21. `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
22. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track).
23. `csv-viewer` (T5, estimated large, pushed back 10, same reason).
24. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first); `project-config-guards` (T3, estimated medium, pushed back 23, same reason): `config.rb:221`, `rc_config_gateway.rb:70`, `file_requests.rb:143`.
25. `insert-copy` (T4, estimated small).

## Decisions

- Sprint 21 (T2 user request, finder-grep note 31 items 2 and 7): 3 features, 3 backlog; features `finder-grep-b`, `vim-folds-c`, `message-styling` in the user's order.
- Delivered (T2 user request): `finder-grep` merged c9f31292b37e by the user's exception, 1,840,003 total tokens in 128 min, rework 2.
- Estimate medium (T2): vim-folds-windows 1,095,387 / 96 min, finder-grep 1,840,003 / 128 min; one of the last two over 1,200,000, no size up.
- Critical (T0 rule a): `finder-grep-b` carries the sprint-20 review security Low (4) at `grep.rb:164`.
- Security (T3, the user's item 6): review Low (3) `plugin.rb:186` goes with `finder-streaming` (Pool 10), the user's async place for the open-time read.
- Aging (T2): `vim-case-operators`, `vim-folds-c` at 4 and `background-detect`, `search-count`, `ui-groups` at 3, each with the user's Sprint 21 order as reason.
- Trial (T1): routing live from 93f4845c3a85; 0 of 6 non-critical deliveries at `agent/high` so far (finder-grep ran `agent/session`).
