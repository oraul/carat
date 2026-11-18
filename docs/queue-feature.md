# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 18

1. `facet-palette` (T2 user request, estimated small, Facet wave 1 item 4): float borders are FAINT, held to 3:1 (`test/domain_theme.rb:13`); dark DIM on PANEL 4.35:1; light SEARCH 1.31:1 and SELECTION 1.26:1 (`carat/domain/themes.rb:262`, `:264`), the current match differing by hue only (`:105`); at 256 colors PANEL_NC and BG both 234 (`:212`); search gold, the command pill yellow (`:137`). Fix outline: a BORDER role #3b4157 / #c9cdd9, exempt from 3:1 like guides; PANEL_DIM #a4aabd / #5c6173; SEARCH #4a4129 / #f7e3a1, the current match strong and bold, the match count on the command line; a stronger light SELECTION; light PANEL #eceef3; PANEL_NC pinned to 233 at 256 colors; COMMAND and the query pickers cyan; the start sparkle (`carat/domain/start_art.rb:27`) sapphire. Accepted when theme rows pin each value on both palettes, light SELECTION above 1.26:1, and frame rows show a bold current match and the count. Backlog: none.
2. `background-default` (T2 user request, estimated medium, Facet wave 1 item 5): the default `option.background terminal` (`config/default.caratrc:59`, read at `carat/adapters/editor_assembly.rb:532`) leaves the theme's background unpainted. Fix outline: default `theme`, carat-dark or carat-light chosen from the terminal's reported background (OSC 11), fallback carat-dark, a theme the configuration names kept; `carat/adapters/key_decoder.rb` swallows the reply. Accepted when rows show the background painted by default, a light reply choosing carat-light, a dark or no reply carat-dark, and no reply byte reaching a key. Backlog: none.

## Pool

1. `vim-folds-windows` (T2 user request, estimated medium, pushed back 1, reason: the user's Sprint 18 choice): Insert mode in a closed fold edits its hidden line (`carat/use_cases/arrange_view.rb:60`); closed windows keep folds tracked (`carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`); marked copies outlive a plugin edit (`carat/domain/buffer.rb:648`); accepted by `zfjiX` open, X on row 0, 1 fold list after `zfj<C-w>s<C-w>c`; 5 vim-folds-b headings.
2. `vim-folds-c` (T2 user request, estimated medium, pushed back 1, same reason): zR, zM, zj, zk, [z, ]z unbound (`config/default.caratrc:186` to `:191`, `carat/use_cases/actions/fold_handler.rb:43`); accepted by compatibility rows and a table-driven test, counts and operators as Neovim.
3. `vim-case-operators` (T2 user request, estimated medium, pushed back 1, same reason): g~, gu, gU missing (`docs/compatibility.md:106`); accepted by `g~w`, `guiw`, `gUU`, `g~~`, `3guu`, `.` as Neovim.
4. `vim-folds-d` (T2 user request, estimated medium, after `vim-folds-c`): `:fold`, `:foldopen`, `:foldclose`; 2 sprint-16 fold headings (`carat/domain/buffer.rb:695`); the vim-folds-a findings.
5. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: its rules and list gaps name no location or entry): "### MarkdownText.parse runs the marker scan twice per line", `format_docs.rb:36` framed flag.
6. `git-panel` plugin (T2 user request, estimated large, pushed back 4, reason: large and unsplit, its split drawn at its start), after `git-signs-transport`.
7. `ui-groups` (T2 user request, estimated small, Facet wave 1 item 2): WinBar, WinBarNC, FloatFooter, Folded, CursorLineSign, StatusLineDim, PmenuKind split; EndOfBuffer, Question painted.
8. Facet wave 2 (T2 user request, estimated medium each, `cursor-and-messages`, `listchars-folds` estimated small): `gutter-signcolumn` (one cell, after `sign-colors`), `match-paren` (never painted, `carat/domain/themes.rb:117`), `cursor-and-messages`, `status-winbar-tabs`, `listchars-folds`.
9. Facet wave 3 (T2 user request, estimated medium each, `float-polish` estimated small, after `bench-scenarios`): `border-vocabulary` (API 2.10), `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`.
10. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens` (with `plugin-protocol-a`), `finder-refined`, `key-hints-dock`, `explorer-rows`.
11. Facet wave 5 (T2 user request, estimated medium each, `explorer-git` estimated large): `start-gem` (a test card first), `diagnostic-text` (cursor line only), `explorer-git` (a security review).
12. `lint-panel` (T2 user request, estimated large, pushed back 1, reason: large, split at its start): diagnostics; `:grep :make :cnext :copen`.
13. `vim-increment` (T2 user request, estimated small, part b of `vim-case-increment`): `<C-a>`, `<C-x>` (`docs/compatibility.md:212`).
14. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
15. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no user-visible effect): `json.rb:72`, `test/lint.rb:255`.
16. `plugin-protocol-a`, `formatting` (T5 roadmap 14, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
17. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5), `dogfooding`, `ux-fixes-b` (T2 user request) (estimated medium each).
18. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each).
19. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4, reason: after the UI track).
20. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
21. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10, reason: after the UI track).
22. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, untrusted keymap lines, `rc_config_gateway.rb:70` Low (3).
23. `insert-copy` (T4, estimated small).

## Decisions

- `guide-colors` delivered as written, off Sprint 18 (T2 user request): item 1 at 7d9bf2a, the user's "Design wave 1 first" (2026-11-18); `facet-palette`, `background-default` keep their order.
- Estimate medium, not small (T2, size rule): theme rows palette-narrow 736,843 / 51.2 min, bar-colors 879,991 / 48.2, ux-fixes-a 894,511 / 54.0, all over small's 500k and 25 min; 1 of the last 2 over (vim-line-commands-c 3,966,863 of 1.2M), no size up.
- No split (T2, size rule): 2 testable parts (the GUIDE and GUIDE_SCOPE roles, the scope glyph), under 3; no `tools/rules.sh` edit.
- Security first empty (T0): sprint-17 security 6/6 first pass, no periodic finding pending, no High or Medium at 8 or above.
- sprint-17-records retros (T1, backlog lane): note 10 (bench 4,147 output, 6 calls, no code) is `bench-skip-no-code`; notes 8 (reviews 30,387 of 72,515 output, advisory-only rounds) and 9 (3 hand edits) to findings.
- Overrun vim-line-commands-c (T1 note): 3,966,863 of 1.2M at rework 6, queued as `round-limit-resume` in the backlog lane.
- `vim-folds-windows`, `vim-folds-c`, `vim-case-operators` to Sprint 19 in that order (T2, pushed back 1): the user's choice.
