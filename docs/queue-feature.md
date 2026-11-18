# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 17

1. `vim-folds-b` (T2 user request, correctness of part a, estimated medium, part b of 3, pushed back 1): the crossing test of `carat/domain/folds.rb:85` matches a fold starting on the new fold's first row, so `zf3jzozfj` on rows 0 to 3 leaves [0,3] twice where Vim nests [0,1]; `Buffer#revert_to` (`carat/domain/buffer.rb:676`) rolls back a failed plugin edit but not the folds its splice shifted (`:720`); in Insert mode the cursor's closed fold stays closed (`carat/use_cases/arrange_view.rb:60`, `frame_presenter.rb:734`, `:829`), so i, a, I, A edit its hidden first line; a closed split or tab page keeps its folds tracked and shifted on every edit (`carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`). Fix outline: folds nest, revert, and open as Neovim's. Accepted when rows show `zf3jzozfj` nesting, `[[2,6],[2,3]]` in `test/domain_folds.rb`, a reverted plugin edit leaving folds as before, `zfjiX` with the fold open and X on row 0, and 1 fold list after `zfj<C-w>s<C-w>c`. Backlog: "### A closed window's folds stay tracked and are shifted on every edit", "### Layout#close frees a window without untracking its folds", "### Closing a split or a tab never untracks its windows' folds".
2. `vim-line-commands-c` (T2 user request, estimated medium, part c of 3): `:normal` and `:p` are missing, 0 rows in `docs/compatibility.md`, the commands a `:g` most often runs besides `:s` and `:d`; the sprint-16 review found part b's text garbled at `docs/compatibility.md:332` ("`:s`, `:A range comes ..."), `place_cursor` (`carat/use_cases/ex/line_command_handler.rb:52`) clamping by hand beside `EditorState#clamp_col`, `addresses_in` (`join_command_handler.rb:70`) re-reading the range text beside `ExRange.resolve`, and map entries missing `RegisterCount.parse_count` (`docs/codebase-map.md:422`), `Registers.unnamed?` (`:234`), `Buffer#transaction_size` (`:260`). Fix outline: the two commands as Neovim; one clamp; the range's address count from `ExRange`; the sentence and map fixed. Accepted when compatibility rows and a table-driven test show `:normal`, `:{range}normal`, `:g/x/normal`, `:p`, `:{range}p` as Neovim, and the `:j`, `:>`, `:<` rows unchanged. Backlog: "## The ex commands a global most often runs besides :s and :d".

## Pool

1. `markdown-reading-e` (T2 user request, estimated medium, pushed back 3, reason: its rules and list gaps name no location or entry): "### MarkdownText.parse runs the marker scan twice per line", `format_docs.rb:36` framed flag.
2. `vim-folds-c` (T2 user request, estimated medium, after `vim-folds-b`): zR, zM, zj, zk, [z, ]z, `:fold`, `:foldopen`, `:foldclose`, the vim-folds-a put, visual, column, and want_col findings, "### Scrolls step into a closed fold's hidden rows (sprint-16 sweep quality)".
3. `git-panel` plugin (T2 user request, estimated large, pushed back 3, reason: large and unsplit, its split drawn at its start), `git-signs-transport` merged before it.
4. `ux-pass-2` (T2 user now-request, estimated medium, pushed back 3, reason: no item list until the user names it).
5. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics; `:grep :make :cnext :copen`.
6. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `vim-case-increment` (T2 user request, estimated medium each).
7. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no user-visible effect): `json.rb:72`, `test/lint.rb:255`.
8. `plugin-protocol-a`, `formatting` (T5 roadmap 14, estimated medium each, pushed back 2): "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
9. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5), `dogfooding`, `ux-fixes-b` (T2 user request) (estimated medium each).
10. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each).
11. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4, reason: after the UI track).
12. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
13. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10, reason: after the UI track).
14. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, untrusted keymap lines, `rc_config_gateway.rb:70` Low (3).
15. `insert-copy`, `bench-scenarios` (T4, estimated small each): bench skips 4 scenarios, lh-float, lh-winbar, n, palette (`bench/run.sh:73`).

## Decisions

- 3 features, 3 backlog (T2): `tab-close-d` and `vim-folds-b` carried from Sprint 16 unmerged at places 1 and 2, `vim-line-commands-c` third; sprint-16 closed with 6 merged, 2 of them beyond the sprint (sprint-size-six, plugin-lazy-activate).
- `tab-close-d` delivered as written and removed (T2 user-reported bug): Sprint 16 item 1 at 94155c0, carried to Sprint 17 place 1 and merged with it; its 2 backlog headings close with it.
- `vim-line-commands-c` drawn third (T2 user request): its part b merged at 25604e0ec359 (893,872 total, under 1,200,000), and it takes 4 sprint-16 findings on that code (review notes 4, 5; sweep 20, 21, 25, 27).
- `markdown-reading-e`, `git-panel`, `ux-pass-2` pushed back to 3 (T2 aging): each with its written reason above; `vim-folds-c` waits on `vim-folds-b`, a feature never ahead of its track.
- Estimated medium, no size up (T2): vim-line-commands-b 893,872 in 61.1 min, tab-close-c 830,180 in 54.5; of the lane's last 2 rows only vim-folds-a went over (1,678,269).
- Sweep 28 (scroll over a closed fold, `scroll_window.rb:64`) into `vim-folds-c` (T2); sweep 35 dropped as a duplicate of `bench-scenarios` (T4).
