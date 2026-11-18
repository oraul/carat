# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 18

None left: `guide-colors`, `facet-palette`, `background-default` fill 3 of 3.

## Pool

1. `search-count` (T2 user request, estimated medium, Facet wave 1 item 4 part b, split from `facet-palette`): after a search or `n` the command line shows no match count, where Neovim shows its searchcount, `[3/12]`, at the right of the command line (shortmess-=S, the main session's call); counted under `SearchBudget` (`carat/domain/search_budget.rb`) from `FindMatch` (`carat/use_cases/search/find_match.rb`), painted by `carat/adapters/frame_presenter.rb`. Accepted when frame rows show `[3/12]` at the right after `/` and after `n`, a count past the budget shown as Neovim does, and the `n` bench held.
2. `background-detect` (T2 user request, estimated medium, Facet wave 1 item 5 part b): the painted default is carat-dark everywhere; the accepted plan picks carat-light on a light terminal. Outline: ask OSC 11 at startup (`carat/drivers/ansi_terminal.rb`), `carat/adapters/key_decoder.rb` swallows the reply, a named theme kept; macOS Terminal 26+, Ptyxis 26.04+. Accepted when rows show a light reply choosing carat-light, a dark or no reply carat-dark, startup not waiting, and no reply byte reaching a key. Backlog: none.
3. `vim-folds-windows` (T2 user request, estimated medium, pushed back 1, reason: the user's Sprint 18 choice): Insert mode in a closed fold edits its hidden line (`carat/use_cases/arrange_view.rb:60`); closed windows keep folds tracked (`carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`); marked copies outlive a plugin edit (`carat/domain/buffer.rb:648`); accepted by `zfjiX` open, X on row 0, 1 fold list after `zfj<C-w>s<C-w>c`; 5 vim-folds-b headings.
4. `vim-folds-c` (T2 user request, estimated medium, pushed back 1, same reason): zR, zM, zj, zk, [z, ]z unbound (`config/default.caratrc:186` to `:191`, `carat/use_cases/actions/fold_handler.rb:43`); accepted by compatibility rows and a table-driven test, counts and operators as Neovim.
5. `vim-case-operators` (T2 user request, estimated medium, pushed back 1, same reason): g~, gu, gU missing (`docs/compatibility.md:106`); accepted by `g~w`, `guiw`, `gUU`, `g~~`, `3guu`, `.` as Neovim.
6. `vim-folds-d` (T2 user request, estimated medium, after `vim-folds-c`): `:fold`, `:foldopen`, `:foldclose`; 2 sprint-16 fold headings (`carat/domain/buffer.rb:695`); the vim-folds-a findings.
7. `markdown-reading-e` (T2 user request, estimated medium, pushed back 4, reason: its rules and list gaps name no location or entry): "### MarkdownText.parse runs the marker scan twice per line", `format_docs.rb:36` framed flag.
8. `git-panel` plugin (T2 user request, estimated large, pushed back 4, reason: large and unsplit, its split drawn at its start), after `git-signs-transport`.
9. `ui-groups` (T2 user request, estimated small, Facet wave 1 item 2): WinBar, WinBarNC, FloatFooter, Folded, CursorLineSign, StatusLineDim, PmenuKind split; EndOfBuffer, Question painted; "### facet-palette dropped the brief's PANEL_DIM".
10. Facet wave 2 (T2 user request, estimated medium each, `cursor-and-messages`, `listchars-folds` estimated small): `gutter-signcolumn` (one cell, after `sign-colors`), `match-paren` (never painted, `carat/domain/themes.rb:117`), `cursor-and-messages`, `status-winbar-tabs`, `listchars-folds`.
11. Facet wave 3 (T2 user request, estimated medium each, `float-polish` estimated small, after `bench-scenarios`): `border-vocabulary` (API 2.10), `window-surfaces`, `prompt-in-float`, `dim-backdrop`, `float-polish`.
12. Facet wave 4 (T2 user request, estimated medium each): `plugin-ui-tokens` (with `plugin-protocol-a`), `finder-refined`, `key-hints-dock`, `explorer-rows`.
13. Facet wave 5 (T2 user request, estimated medium each, `explorer-git` estimated large): `start-gem` (a test card first), `diagnostic-text` (cursor line only), `explorer-git` (a security review).
14. `lint-panel` (T2 user request, estimated large, pushed back 1, reason: large, split at its start): diagnostics; `:grep :make :cnext :copen`.
15. `vim-increment` (T2 user request, estimated small, part b of `vim-case-increment`): `<C-a>`, `<C-x>` (`docs/compatibility.md:212`).
16. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks` (T2 user request, estimated medium each).
17. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no user-visible effect): `json.rb:72`, `test/lint.rb:255`.
18. `plugin-protocol-a`, `formatting` (T5 roadmap 14, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
19. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5), `dogfooding`, `ux-fixes-b` (T2 user request) (estimated medium each).
20. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each).
21. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4, reason: after the UI track).
22. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
23. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10, reason: after the UI track).
24. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, untrusted keymap lines, `rc_config_gateway.rb:70` Low (3).
25. `insert-copy` (T4, estimated small).

## Decisions

- `background-default` part a delivered (T2 user request, Facet decision 1): background painted by default on carat-dark, a named theme kept.
- Split, `background-detect` Pool 2 (T2, size rule): 4 map areas (3, 4, 5, 17) over the scouts' 3; behind `search-count` by wave order (item 4, then 5).
- Estimate medium (T2): last ten feature rows 801,482 to 3,966,863 tokens, none under 500k; facet-palette 1,273,459 over, guide-colors 922,993 under, no size up.
- No `tools/rules.sh` edit (T1): part a is the default, options, generated config, docs, frame tests.
- Security first empty (T0): facet-palette and groom-proof high 0, medium 0; no periodic finding pending.
- facet-palette retros 10, 11 (rework 2 with 0 blocking, about 369,000 of 736,922 output after the first pass) for `rework-review-repeat`, 12 (check and merge 30.6% of output) for `merge-output-cap`, as findings (T1, pipeline only for a defect).
- PANEL_DIM into `ui-groups` (T2, same domain): retro 11, 0 PANEL_DIM in `carat/domain/themes.rb` at caf4532ac051.
- Overruns 7 to 9 (T1): facet-palette check 573,120 of 200,000 output, total 1,273,459 of 1.2M, in retros 10, 11.
- groom-proof notes 16 to 22 left to the backlog lane (T1, brief: no backlog-lane file): its run #209.
