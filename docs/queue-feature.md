# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 25

The user-approved exception (2026-11-21, the design council): `comment-operator` runs first in the feature lane after `facet-design-doc`, outside the 3.

1. `cmdline-completion` (T2 user request, estimated medium): Where: `config/default.caratrc:800` (no `<Tab>`), `carat/ports/file_port.rb:41` (`list` reads every entry), `follow_palette.rb` (the `>` popup), `docs/compatibility.md:259`. Why: the council's user types every path in full, 0 completions at `:`; cmdline-editing's part 2, split at c281c9b. Fix outline: `<Tab>` at `:` completes a command name at the start (the ExHandlers, compatibility.md's precedence) and a path for `:e`, `:w`, `:sp`, `:vs`, `:tabe`, `:r`, `:cd`, relative to the working directory by the file port, no shell, directories ending `/`, outside only when typed (`../`, `/`, `~`), a bounded count per directory named in the doc; the popup above the line (Pmenu, PmenuSel, PmenuMatch, docs/design.md); `<Tab>`, `<S-Tab>` cycle and insert; `<C-n>`, `<C-p>` keep `>`'s meaning; Esc closes the menu, then the line; keymap, `make gen-config`, actions.md, compatibility.md (no `wildmode`/`wildoptions`, only paths), README. Accepted when a table test covers a name, a directory, a file, no match, many, cycling back, a space in a path, the bounded read; the popup within the cursor scenario's allocations; `lh` 25.0; each ADDED scenario names its test. Backlog: none.

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

- Security first (T0): none; 0 review.periodic in 3 pending runs; sprint-24 High 0, Medium 0 at 8+.
- Order (T2 user request, council decision 2 of 2026-11-21): `cmdline-editing` is Sprint 25 feature 2, ahead of `folded-row`; the basics, then `folded-row`, `float-painter`, `ui-groups`, `picker-speed`, then wave 3.
- Split (T2): 2 testable parts (9 editing keys; completion, popup, bounded read); `cmdline-completion` is feature 3.
- Size (T2): medium; mediums 1.23M to 2.19M; showtabline 1.37M over, comment-operator 1.29M not; critical none.
- Retro (T1): showtabline 3 to 6, backlog-per-file 2 to 5, the backlog lane's: findings file.
