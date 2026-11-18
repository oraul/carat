# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 18

1. `background-default` (T2 user request, estimated medium, Facet wave 1 item 5): the default `option.background terminal` (`config/default.caratrc:59`, read at `carat/adapters/editor_assembly.rb:532`) leaves the theme's background unpainted. Fix outline: default `theme`, carat-dark or carat-light chosen from the terminal's reported background (OSC 11), fallback carat-dark, a theme the configuration names kept; `carat/adapters/key_decoder.rb` swallows the reply. Accepted when rows show the background painted by default, a light reply choosing carat-light, a dark or no reply carat-dark, and no reply byte reaching a key. Backlog: none.

## Pool

1. `search-count` (T2 user request, estimated medium, Facet wave 1 item 4 part b, split from `facet-palette`): after a search or `n` the command line shows no match count, where Neovim shows its searchcount, `[3/12]`, at the right of the command line (shortmess-=S, the main session's call); counted under `SearchBudget` (`carat/domain/search_budget.rb`) from `FindMatch` (`carat/use_cases/search/find_match.rb`), painted by `carat/adapters/frame_presenter.rb`. Accepted when frame rows show `[3/12]` at the right after `/` and after `n`, a count past the budget shown as Neovim does, and the `n` bench held.
2. `vim-folds-windows` (T2 user request, estimated medium, pushed back 1, reason: the user's Sprint 18 choice): Insert mode in a closed fold edits its hidden line (`carat/use_cases/arrange_view.rb:60`); closed windows keep folds tracked (`carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`); marked copies outlive a plugin edit (`carat/domain/buffer.rb:648`); accepted by `zfjiX` open, X on row 0, 1 fold list after `zfj<C-w>s<C-w>c`; 5 vim-folds-b headings.
3. `vim-folds-c` (T2 user request, estimated medium, pushed back 1, same reason): zR, zM, zj, zk, [z, ]z unbound (`config/default.caratrc:186` to `:191`, `carat/use_cases/actions/fold_handler.rb:43`); accepted by compatibility rows and a table-driven test, counts and operators as Neovim.
4. `vim-case-operators` (T2 user request, estimated medium, pushed back 1, same reason): g~, gu, gU missing (`docs/compatibility.md:106`); accepted by `g~w`, `guiw`, `gUU`, `g~~`, `3guu`, `.` as Neovim.
5. `vim-folds-d` (T2 user request, estimated medium, after `vim-folds-c`): `:fold`, `:foldopen`, `:foldclose`; 2 sprint-16 fold headings (`carat/domain/buffer.rb:695`); the vim-folds-a findings.
6. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: its rules and list gaps name no location or entry): "### MarkdownText.parse runs the marker scan twice per line", `format_docs.rb:36` framed flag.
7. `git-panel` plugin (T2 user request, estimated large, pushed back 4, reason: large and unsplit, its split drawn at its start), after `git-signs-transport`.
8. `ui-groups` (T2 user request, estimated small, Facet wave 1 item 2): WinBar, WinBarNC, FloatFooter, Folded, CursorLineSign, StatusLineDim, PmenuKind split; EndOfBuffer, Question painted.
9. Facet wave 2 (T2 user request, estimated medium each, `cursor-and-messages`, `listchars-folds` estimated small): `gutter-signcolumn` (one cell, after `sign-colors`), `match-paren` (never painted, `carat/domain/themes.rb:117`), `cursor-and-messages`, `status-winbar-tabs`, `listchars-folds`.
10. Facet wave 3 (T2 user request, estimated medium each, `float-polish` estimated small, after `bench-scenarios`): `border-vocabulary` (API 2.10), `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`.
11. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens` (with `plugin-protocol-a`), `finder-refined`, `key-hints-dock`, `explorer-rows`.
12. Facet wave 5 (T2 user request, estimated medium each, `explorer-git` estimated large): `start-gem` (a test card first), `diagnostic-text` (cursor line only), `explorer-git` (a security review).
13. `lint-panel` (T2 user request, estimated large, pushed back 1, reason: large, split at its start): diagnostics; `:grep :make :cnext :copen`.
14. `vim-increment` (T2 user request, estimated small, part b of `vim-case-increment`): `<C-a>`, `<C-x>` (`docs/compatibility.md:212`).
15. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
16. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no user-visible effect): `json.rb:72`, `test/lint.rb:255`.
17. `plugin-protocol-a`, `formatting` (T5 roadmap 14, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
18. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5), `dogfooding`, `ux-fixes-b` (T2 user request) (estimated medium each).
19. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each).
20. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4, reason: after the UI track).
21. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
22. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10, reason: after the UI track).
23. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, untrusted keymap lines, `rc_config_gateway.rb:70` Low (3).
24. `insert-copy` (T4, estimated small).

## Decisions

- `facet-palette` delivered, off Sprint 18 (T2 user request): item 1 at 24f502d, the palette part as written; `background-default` keeps its place.
- Split, `search-count` queued Pool 1 (T2, size rule): 3 map areas (14 `themes.rb`, 13 `start_art.rb` and the command line, 6 the search) and a new behavior; the palette part (theme rows, bold current match) now, the count `[3/12]` next, not a 4th Sprint 18 feature.
- Estimate medium, not small (T2, size rule): palette-narrow 736,843 / 51.2 min, bar-colors 879,991 / 48.2, guide-colors 922,993 / 73.0, all over small's 500k and 25 min; 1 of the last 2 over (vim-line-commands-c 3,966,863 of 1.2M, guide-colors under), no size up.
- No `tools/rules.sh` edit (T1): the brief touches the themes, the start art, and theme tests only.
- Security first empty (T0): guide-colors security high 0, medium 0, low 0; no periodic finding pending; sprint-17 none at 8 or above.
- guide-colors retros to findings (T1, no pipeline item outside a defect): 7 (advisory-only rework 1, 83,604 output) merged into the sprint-17-records advisory-round entry; 8 (merge 26,423 output, 11 calls), 9 (check 30,277 output, 5 calls) as entries.
- Overrun notes (T1): guide-colors check 230,744 of 200,000 output, total 922,993 under 1.2M, covered by retro 7; vim-line-commands-c 3,966,863 already queued as `round-limit-resume`.
