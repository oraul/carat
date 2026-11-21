# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 25

The user-approved exception (2026-11-21, the design council): `comment-operator` runs first in the feature lane after `facet-design-doc`, outside the 3.

## Pool

1. `set-options` (T2 user request, estimated medium): numeric options PENDING (`set_command_handler.rb:29`); `hidden` on by default, `:colorscheme`, `showtabline`/`stal`, boolean switches.
2. `buffer-picker` (T2 user request, estimated medium): `<leader>fb` buffers, `<leader>fr` recent files, `<leader>fR` resumes the last search (`finder-resume` folded in).
3. `folded-row` (T2 user request, estimated medium, pushed back 1, reason: the basics): a closed fold is one Normal row (`frame_presenter.rb:799`); accepted when frame rows show Folded, padded, both themes, ascii, 16 colors, NO_COLOR.
4. `float-painter` (T2 user request, estimated medium); `ui-groups` (T2 user request, estimated small, pushed back 5, reason: the waves): PANEL_DIM, the message row's indicators; `picker-speed` (T2 user request, estimated medium, pushed back 1): the float, finder, palette speed gate.
5. `finder-switch` (T2 user request, estimated medium, pushed back 2, reason: the basics): `<C-g>` keeps the query, `<leader>fw`; `finder-rows` (T2 user request, estimated large, pushed back 3, reason: the user's order of 2026-11-21, critical e carat/plugins/finder/plugin.rb): PmenuSel, PmenuMatch, left cut, grep rows, the NormalFloat hole.
6. Facet waves 3 to 5 (T2 user request, estimated medium each): `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`, `separator-styles` (small: `frame_presenter.rb:107`, `:109`), `one-accent`, `glyph-audit` (small: design.md section 7's 8 and 8 rows, `icons.rb:58`); `plugin-ui-tokens` ("### style_float checks a span's start column only from below (sprint-23 review security Low (3), disputed)", token length, PmenuExtra, float resolved thrice), `finder-refined`, `key-hints-dock`, `explorer-rows`; `start-gem`, `diagnostic-text`, `explorer-git`.
7. `finder-preview-gutter` (T2 user request, estimated small, pushed back 1, reason: the waves); `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops` (medium each, pushed back 1); `search-count` (medium, pushed back 5): no match count or pager.
8. `background-theme` (T2 user request, estimated medium, pushed back 2, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries (split introducer, unanswered query, late tail).
9. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 2, critical a carat/plugin_api.rb): "### The file finder shows paths as the file lists them", "### File finder rows and preview title show the listed path unsanitized", "### Grep.safe passes bidi and zero-width format code points into rows", "### Grep rows still pass the other invisible format code points".
10. `vim-folds-d` (T2, estimated medium, pushed back 1); `markdown-reading-e` (T2, estimated medium, pushed back 5, reason: no location): the double marker scan.
11. Async (T2 user request, estimated medium each, pushed back 1): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming` ("### The grep picker reads every listed file synchronously on the editor (sprint-20 review security Low (3), plugin.rb:186)", its quality twin), `program-jobs`.
12. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 4, reason: after the UI track); `git-panel` (T2, estimated large, pushed back 5, same); `claude-bridge`, `claude-workflow` (T2 ideas, estimated large); `lint-panel` (T2, estimated large, pushed back 2).
13. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, estimated medium each).
14. `theme-tuning`, `semantic-highlight` (T5 roadmap, estimated medium, large); `plugin-protocol-a`, `formatting` (T5, estimated medium, pushed back 2); `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, medium each).
15. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 6, reason: after the UI track); `csv-viewer` (T5, large, pushed back 10).
16. `bidi-controls` (T3 Lows, estimated small, pushed back 11, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, small).

## Decisions

- Security first (T0): none; 0 review.periodic in 3 pending runs (cmdline-editing, lane-isolation, review-in-openspec); sprint-24 High 0, Medium 0 at 8+.
- Deliver (T2 user request, council decision 2 of 2026-11-21): `cmdline-completion` as Sprint 25 item 1 wrote it; Sprint 25 drained, 0 of 3 left, waits for `/sprint`.
- Split (T2): none; 2 testable parts sharing one popup (command names; paths with the bounded read), under 3.
- Size (T2): large, one up; the lane's last two medium over 1.2M (showtabline 1,365,817; cmdline-editing 1,418,893 in 131 min); critical d carat/drivers/disk_files.rb (typed `../`, `/`, `~` paths).
- Acceptance (T1, cmdline-editing note 3): its rework round came from bench, grep allocs 774.4 to 779.9 after the check passed; allocations compared before the check.
- Retro (T1): cmdline-editing 3 to 6 to the findings file, 4 into `scout-prune`, 5, 6 into the medium-budget entry; lane-isolation 1, 2, review-in-openspec 9 to 11 in backlog Pool 11.
