# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 25

1. `tabs-only-dot` (T2 user request, Facet, estimated medium): the active tab still draws a gem (`GEM`, `ASCII_GEM`, `carat/adapters/tab_bar.rb:27`, `:131`) though the user's Facet decision shows only the modified `●` (listchars-folds note 13); the ascii gem and ascii modified mark are both `*`; `test/editor_tab_flows.rb:105` keeps about 60 lines of gem and separator heuristics. Fix outline: the active tab marked by the editor background and bold, the thin separator and fixed-width `●` kept. Accepted when frame rows show the active tab without a gem in both themes, ascii, 16 colors, and NO_COLOR (the gem row fails at 7156f43), a test holds 3:1 contrast with bold carrying focus, the tab-flow table asserts names without the heuristics, and `lh` held. Backlog: "### The ascii gem and the ascii modified mark are both `*`", "### tab_boundary? takes a digit after a gem as a tab boundary", "### Tab-flow tests guess gems and separators with about 60 lines of heuristics (sprint-24 review quality)".
2. `border-vocabulary` (T2 user request, Facet wave 3, estimated large, carried from Sprint 24, critical d carat/plugin_api.rb): a float's border is one bool (`FloatOptions`, `carat/plugin_api.rb:203`) drawn in the global `option.winborder rounded` (`config/default.caratrc:52`); split separators are fixed `│` and `─` (`frame_presenter.rb:107`, `:109`), every edge FloatBorder (`:537`, `:724`). Fix outline: the Facet border vocabulary as named styles a float may request at API 2.13, a 2.12 plugin's bool still honored. Accepted when frame rows draw each style and its ascii fallback, a plugin test requests a style, a 2.12 plugin loads, and `lh-float` is held. Backlog: none.
3. `showtabline` (T2 user request, Facet wave 2, split from status-winbar-tabs-b at 7208588, estimated large): the tab row shows only from two tabs or two files (`carat/domain/buffer_list.rb:223`, read at `carat/use_cases/arrange_view.rb:51`, `frame_presenter.rb:238`); `docs/compatibility.md:510` lists `showtabline` missing. Fix outline: `option.showtabline` 0, 1, 2, default 2. Accepted when a table-driven test and frame rows show each value with one and two files (the one-file row at the default fails at 7208588), a `.caratrc` row with `make gen-config` current, its compatibility row, and `lh` held. Backlog: none.

## Pool

1. `folded-row` (T2 user request, Facet wave 2, estimated medium): a closed fold is one Normal row (`frame_presenter.rb:799`); accepted when shown in Folded, one cell of padding, both themes, ascii, 16 colors, NO_COLOR.
2. `finder-switch` (T2 user request, estimated medium, pushed back 1, reason: the waves): `<C-g>` switches files and grep keeping the query, `<leader>fw` greps the word.
3. `finder-rows` (T2 user request, estimated large, pushed back 2, same reason, critical e carat/plugins/finder/plugin.rb): PmenuSel band, PmenuMatch, paths cut left, grep rows; 1 entry (the NormalFloat hole).
4. Facet wave 3 rest (T2 user request, estimated medium each): `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`.
5. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens` ("### style_float checks a span's start column only from below (sprint-23 review security Low (3), disputed)", 3 more: token length, PmenuExtra, float resolved three times), `finder-refined`, `key-hints-dock`, `explorer-rows`.
6. Facet wave 5 (T2 user request, estimated medium each): `start-gem`, `diagnostic-text`, `explorer-git`.
7. `finder-resume`, `finder-preview-gutter` (T2 user request, estimated small each, pushed back 1, reason: the waves); `grep-finish`, `explorer-filter` (T2 user request, estimated medium each, pushed back 1, same reason).
8. `background-theme` (T2 user request, estimated medium, pushed back 2, same reason, critical d carat/drivers/ansi_terminal.rb): the 3 OSC 11 entries (split introducer, unanswered query, late reply's tail).
9. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 2, same reason, critical a carat/plugin_api.rb): "### The file finder shows paths as the file lists them", "### File finder rows and preview title show the listed path unsanitized", "### Grep.safe passes bidi and zero-width format code points into rows", "### Grep rows still pass the other invisible format code points".
10. `search-count`, `ui-groups` (T2 user request, estimated medium, small, pushed back 5, reason: the waves): 3 entries (no match count or pager, PANEL_DIM, the message row's visual indicators).
11. `finder-ranking`, `finder-layout`, `picker-speed`, `explorer-file-ops` (T2 user request, estimated medium each, pushed back 1, same reason).
12. `vim-folds-d` (T2, estimated medium, pushed back 1); `markdown-reading-e` (T2, estimated medium, pushed back 5, reason: no location): the double marker scan.
13. Async (T2 user request, estimated medium each, pushed back 1, reason: the waves): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` ("### The grep picker reads every listed file synchronously on the editor (sprint-20 review security Low (3), plugin.rb:186)", its quality twin), `program-jobs`.
14. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track).
15. `git-panel` (T2 user request, estimated large, pushed back 5, same reason); `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each); `lint-panel` (T2, estimated large, pushed back 2).
16. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, estimated medium each).
17. `set-options`, `theme-tuning`, `semantic-highlight` (T5 roadmap, estimated medium, medium, large): 4 roadmap entries (`:set` options, boolean switches, theme tuning, semantic highlighting).
18. `plugin-protocol-a`, `formatting` (T5, estimated medium each, pushed back 2): visual selection, ranges and virtual text; `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
19. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track); `csv-viewer` (T5, estimated large, pushed back 10, same reason).
20. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, estimated small).

## Decisions

- Security first (T0): none; sprint-24 review and sweep High 0, Medium 0.
- Sprint 25 (T2): 3 features, 3 backlog; `tabs-only-dot` first (listchars-folds note 13), `border-vocabulary` carried, `showtabline` Pool 1.
- Size (T2): one up, the last two feature runs over: status-winbar-tabs-b 2,192,549 and listchars-folds 1,499,684 of 1.2M.
- Fold (T1): pool entry lists shortened to counts, security headings kept, to fit 17,969 bytes (review-trust-lows note 14).
