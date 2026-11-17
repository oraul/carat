# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 16

1. `vim-line-commands-b` (T2 user request, estimated medium, pushed back 1): `:j`, `:>`, `:<` are missing, 0 rows in `docs/compatibility.md`; the sprint-14 line-command code repeats itself: `place_cursor` and the bang, range, and target prelude copied in `carat/use_cases/ex/move_command_handler.rb:81`, `:38` and `copy_command_handler.rb:67`, `:19`, `REPORT = 2` private in 3 files, "E477: No ! allowed" spelled in 5; `ExRange.target` (`carat/domain/ex_range.rb:67`, `:73`, `:84`, `:97`) answers E16 or Not implemented where `resolve` answers Not implemented, on a 1-based line beside 0-based rows; map area 12 (`docs/codebase-map.md:402`, `:404`) stops at `:d`. Fix outline: the three commands as Neovim; one prelude, REPORT, and E477; one address code; the map names the commands. Accepted when compatibility rows and a table-driven test show `:j`, `:j!`, `:{range}j`, `:>`, `:>>`, `:<` with ranges and counts as Neovim does, `:m` and `:t` rows unchanged. Backlog: "### :m and :t copy one prelude, cursor placement, and REPORT (sprint-14 review and sweep quality)", "### ExRange.target answers other errors and another base than resolve (sprint-14 review and sweep quality)", "### The map's area 12 omits the line commands (sprint-14 sweep quality)".
2. `tab-close-d` (T2 user-reported bug, estimated medium): under `option.gt buffers` the explorer's t with only the tree left opens tab page 2 and leaves tab page 1 holding only the tree (`carat/use_cases/plugins/window_requests.rb:211`, untested), a state `test/editor_tab_flows.rb` rejects; the finder's tab pick still opens a tab page (`carat/plugins/finder/plugin.rb:327`, against `carat/plugins/explorer/plugin.rb:280`); the comment at `explorer/plugin.rb:253` says t opens a tab page. Fix outline: t with no file window opens one as l does; the finder's pick follows `option.gt` as the explorer's does. Accepted when editor rows show t from a lone tree and the finder's tab pick under `option.gt buffers` and `tabs`, none leaving a tab page of only the tree. Backlog: "### The explorer's t with no file window opens a tab page holding only the tree", "### The finder's tab pick opens a tab page under option.gt buffers (sprint-14 sweep quality)".
3. `vim-folds-b` (T2 user request, correctness of part a, estimated medium, part b of 3): the sprint-15 review found shipped folds wrong: the crossing test of `carat/domain/folds.rb:85` matches a fold starting on the new fold's first row, so `zf3jzozfj` on rows 0 to 3 leaves [0,3] twice where Vim nests [0,1]; `Buffer#revert_to` (`carat/domain/buffer.rb:676`) rolls back a failed plugin edit but not the folds its splice shifted (`:720`); in Insert mode the cursor's closed fold stays closed (`carat/use_cases/arrange_view.rb:60`, `frame_presenter.rb:734`, `:829`), so i, a, I, A edit its hidden first line with the cursor at column 0; a closed split or tab page keeps its folds tracked and shifted on every edit (`carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`). Fix outline: folds nest, revert, and open as Neovim's. Accepted when rows show `zf3jzozfj` nesting, `[[2,6],[2,3]]` in `test/domain_folds.rb`, a reverted plugin edit leaving folds as before, `zfjiX` with the fold open and X on row 0, and 1 fold list after `zfj<C-w>s<C-w>c`. Backlog: "### A closed window's folds stay tracked and are shifted on every edit", "### Layout#close frees a window without untracking its folds", "### Closing a split or a tab never untracks its windows' folds".

## Pool

1. `markdown-reading-e` (T2 user request, estimated medium, pushed back 2, reason: its rules and list gaps name no location or entry): with "### MarkdownText.parse runs the marker scan twice per line", `format_docs.rb:36` framed flag.
2. `vim-folds-c`, `vim-line-commands-c` (T2 user request, estimated medium each): folds c takes zR, zM, zj, zk, [z, ]z, `:fold`, `:foldopen`, `:foldclose` and the vim-folds-a put, visual, column, and want_col findings; line c `:normal`, `:p`, "## The ex commands a global most often runs besides :s and :d".
3. `git-panel` plugin (T2 user request, estimated large, pushed back 2, split at its start): after backlog `git-signs-transport`.
4. `ux-pass-2` (T2 user now-request, estimated medium, pushed back 2, reason: no item list; drawn once the user names it).
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
15. `insert-copy`, `bench-scenarios` (T4, estimated small each): bench skips 4 scenarios (`bench/run.sh:69`).

## Decisions

- Security first clear (T0): sprint-15 review security high 0, medium 0, Low (3) 1 at `deliver-change.js:688`; 0 periodic findings in the 2 pending runs; nothing in `security_first`.
- Sprint 16, 3 features, 2 backlog (T2): `vim-line-commands-b`, `tab-close-d`, `vim-folds-b`; the backlog lane holds `secret-patterns`, `git-signs-transport`.
- `vim-folds-b` ahead of `markdown-reading-e` (T2): sprint-15 review notes 2, 3, 4 are correctness bugs in shipped folds; markdown-reading-e's rules and list gaps name 0 locations, pushed back 2.
- Folds split b and c (T2, size rule): vim-folds-a took rework 3, its check passing at 445,555 output tokens against 200,000; b holds the 4 fixes on one fold model, c the 8 commands.
- `vim-line-commands-b` kept whole (T2, size rule): vim-line-commands-a delivered 3 line commands in 890,042 total tokens and 54.5 min, rework 0.
- Estimated medium, no size up (T2): 0 of the last ten feature rows under 500,000 (lowest 736,843); the last two 830,180 and 801,482, under 1,200,000.
- Batch 2's API entries to `plugin-protocol-a` (T5): selection and highlight requests are roadmap 14 features, not fixes.
- 0 `tools/rules.sh` edits in this lane (T2): the items name ex, tab, and fold code only.
