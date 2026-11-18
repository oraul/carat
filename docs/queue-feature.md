# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 17

## Pool

1. `vim-folds-windows` (T2 user request, estimated medium, the rest of `vim-folds-b`, split at its start): in Insert mode the cursor's closed fold stays closed (`carat/use_cases/arrange_view.rb:60`, `carat/adapters/frame_presenter.rb:734`, `:829`), so i, a, I, A edit its hidden first line; a closed split or tab page keeps its folds tracked and shifted on every edit (`carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`). Fix outline: folds open and untrack as Neovim's. Accepted when rows show `zfjiX` with the fold open and X on row 0, and 1 fold list after `zfj<C-w>s<C-w>c`. Backlog: "### A closed window's folds stay tracked and are shifted on every edit", "### Layout#close frees a window without untracking its folds", "### Closing a split or a tab never untracks its windows' folds".
2. `markdown-reading-e` (T2 user request, estimated medium, pushed back 3, reason: its rules and list gaps name no location or entry): "### MarkdownText.parse runs the marker scan twice per line", `format_docs.rb:36` framed flag.
3. `vim-folds-c` (T2 user request, estimated medium, after `vim-folds-windows`): zR, zM, zj, zk, [z, ]z, `:fold`, `:foldopen`, `:foldclose`, the vim-folds-a put, visual, column, and want_col findings, "### Scrolls step into a closed fold's hidden rows (sprint-16 sweep quality)".
4. `git-panel` plugin (T2 user request, estimated large, pushed back 3, reason: large and unsplit, its split drawn at its start), `git-signs-transport` merged before it.
5. `ux-pass-2` (T2 user now-request, estimated medium, pushed back 3, reason: no item list until the user names it).
6. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics; `:grep :make :cnext :copen`.
7. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `vim-case-increment` (T2 user request, estimated medium each).
8. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no user-visible effect): `json.rb:72`, `test/lint.rb:255`.
9. `plugin-protocol-a`, `formatting` (T5 roadmap 14, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
10. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5), `dogfooding`, `ux-fixes-b` (T2 user request) (estimated medium each).
11. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each).
12. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4, reason: after the UI track).
13. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
14. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10, reason: after the UI track).
15. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, untrusted keymap lines, `rc_config_gateway.rb:70` Low (3).
16. `insert-copy`, `bench-scenarios` (T4, estimated small each): bench skips 4 scenarios, lh-float, lh-winbar, n, palette (`bench/run.sh:73`).


## Decisions

- `vim-line-commands-c` delivered as written and removed (T2 user request): Sprint 17 feature item 1 at 84ed58b, the third feature after tab-close-d (#201) and vim-folds-b (#203); the feature sprint drained to 0 items, waiting for `/sprint`.
- Estimate medium, no size up (T2): vim-line-commands-a 890,042 / 54.5 min, vim-line-commands-b 893,872 / 61.1; of the last 2 feature runs only tab-close-d went over (1,654,786), vim-folds-b 904,033 / 44.8.
- No split (T2, size rule): already part c of 3; 2 testable commands over map areas 12 and 5 (`:normal` feeds keys like `carat/use_cases/handle_key.rb`); the clamp, address count, sentence, and map edits add no behavior, held by the unchanged `:j`, `:>`, `:<` rows.
- No merge-gate rule edit (T2): the locations are `carat/use_cases/ex/`, `docs/compatibility.md`, `docs/codebase-map.md`; `tools/rules.sh` untouched.
- Security first empty (T0): no periodic finding in the 2 pending runs, pipeline-diet and vim-folds-b; sprint-16's Medium (9) fixed by moved-review-carry (#199).
- vim-folds-b retros 5, 6, 8 to `backlog.md` (T1): merge 98,694 output / 10 calls, scout 44 of 139 calls, 5 of 5 squash bodies #199 to #203 at 3 lines; backlog-lane work this delivery does not touch; retro 5 merges into the backlog pool's `merge-output-cap`.
- vim-folds-b overrun note 7 dropped (T1): tab-close-d 1,654,786 already placed as a true flag by pipeline-diet-b's plan; pipeline-diet notes 7 to 10 placed there too.
- Map drift to `backlog.md` (T6): `docs/codebase-map.md:55` says 0 to 2 backlog sprint items, `tools/docs_lint.sh:183` checks 3.
