# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 17

1. `vim-line-commands-c` (T2 user request, estimated medium, part c of 3): `:normal` and `:p` are missing, 0 rows in `docs/compatibility.md`, the commands a `:g` most often runs besides `:s` and `:d`; the sprint-16 review found part b's text garbled at `docs/compatibility.md:332` ("`:s`, `:A range comes ..."), `place_cursor` (`carat/use_cases/ex/line_command_handler.rb:52`) clamping by hand beside `EditorState#clamp_col`, `addresses_in` (`join_command_handler.rb:70`) re-reading the range text beside `ExRange.resolve`, and map entries missing `RegisterCount.parse_count` (`docs/codebase-map.md:422`), `Registers.unnamed?` (`:234`), `Buffer#transaction_size` (`:260`). Fix outline: the two commands as Neovim; one clamp; the range's address count from `ExRange`; the sentence and map fixed. Accepted when compatibility rows and a table-driven test show `:normal`, `:{range}normal`, `:g/x/normal`, `:p`, `:{range}p` as Neovim, and the `:j`, `:>`, `:<` rows unchanged. Backlog: "## The ex commands a global most often runs besides :s and :d".

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

- No security first (T0): sprint-16 periodic security Medium (9) `tools/run_state.sh:2759` and Medium (5) `deliver-change.js:933` at 2af0b3aa0990 are fixed by moved-review-carry 1a0551848c13 (#199), merged after it.
- `vim-folds-b` split at its start (T2 user request, size rule): 4 independently testable parts over map areas 8, 11, 13; delivered: the nesting at `folds.rb:85` and the folds `revert_to` leaves shifted (`buffer.rb:676`, `:720`); the rest is `vim-folds-windows`, Pool 1, with the 3 backlog headings.
- `vim-folds-b` estimated large (T2): comparable rows 801,482 to 893,872, sized up as the last two feature runs went over 1,200,000 (plugin-lazy-activate 1,245,262, tab-close-d 1,654,786); vim-folds-a took 1,678,269 in 145.0 min.
- `tab-close-d` merged from place 1 (#201) and `vim-folds-b` delivered from place 1, `vim-line-commands-c` now place 1 (T2): fixes the tab-close-d late finding at `docs/queue-feature.md:30`.
- `vim-folds-windows` in the Pool, not the sprint (T2): Sprint 17 drew its 3 features; no push-back counted below it, `vim-folds-b` was ahead of them; `vim-folds-c` after it, never ahead of its track.
- 7 run notes to `backlog.md` (T1, T6): tab-close-d retro 12 to 14 (merge 60,874/21, reviews 37,844/46, package 60,830/51) and sprint-16-records retro 7 to 9 (bench 11,192/21 over 3 runs) belong to the backlog lane this delivery does not touch; the late finding `docs/findings/tab-close-d.md:11`.
