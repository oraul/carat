# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 16

The user-approved exception: `plugin-lazy-activate` (T2 user request, estimated medium, beyond the sprint, the user-approved exception), Sprint 16's one exemption.

1. `tab-close-d` (T2 user-reported bug, estimated medium, pushed back 1, reason: the user-approved exception goes first): under `option.gt buffers` the explorer's t with only the tree left opens tab page 2 and leaves tab page 1 holding only the tree (`carat/use_cases/plugins/window_requests.rb:211`, untested), a state `test/editor_tab_flows.rb` rejects; the finder's tab pick still opens a tab page (`carat/plugins/finder/plugin.rb:327`, against `carat/plugins/explorer/plugin.rb:280`); the comment at `explorer/plugin.rb:253` says t opens a tab page. Fix outline: t with no file window opens one as l does; the finder's pick follows `option.gt` as the explorer's does. Accepted when editor rows show t from a lone tree and the finder's tab pick under `option.gt buffers` and `tabs`, none leaving a tab page of only the tree. Backlog: "### The explorer's t with no file window opens a tab page holding only the tree", "### The finder's tab pick opens a tab page under option.gt buffers (sprint-14 sweep quality)".
2. `vim-folds-b` (T2 user request, correctness of part a, estimated medium, part b of 3, pushed back 1, reason: the user-approved exception goes first): the sprint-15 review found shipped folds wrong: the crossing test of `carat/domain/folds.rb:85` matches a fold starting on the new fold's first row, so `zf3jzozfj` on rows 0 to 3 leaves [0,3] twice where Vim nests [0,1]; `Buffer#revert_to` (`carat/domain/buffer.rb:676`) rolls back a failed plugin edit but not the folds its splice shifted (`:720`); in Insert mode the cursor's closed fold stays closed (`carat/use_cases/arrange_view.rb:60`, `frame_presenter.rb:734`, `:829`), so i, a, I, A edit its hidden first line with the cursor at column 0; a closed split or tab page keeps its folds tracked and shifted on every edit (`carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`). Fix outline: folds nest, revert, and open as Neovim's. Accepted when rows show `zf3jzozfj` nesting, `[[2,6],[2,3]]` in `test/domain_folds.rb`, a reverted plugin edit leaving folds as before, `zfjiX` with the fold open and X on row 0, and 1 fold list after `zfj<C-w>s<C-w>c`. Backlog: "### A closed window's folds stay tracked and are shifted on every edit", "### Layout#close frees a window without untracking its folds", "### Closing a split or a tab never untracks its windows' folds".

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

- Security first clear (T0): the 2 pending runs, git-signs-transport at 9190f01131a1 and vim-line-commands-b at b15c70846cde, each security high 0, medium 0, low 0, blocking 0, and 0 `review.periodic` findings; nothing in `security_first`.
- `plugin-lazy-activate` delivered first as Sprint 16's one exemption (T2 user request): the brief records the user's "prioritize for now", beyond the sprint, after vim-line-commands-b merged at 25604e0ec359; the exception line above carries `beyond the sprint`, so the sprint counts 0 of it.
- `tab-close-d` and `vim-folds-b` pushed back 1 each (T2): the exception runs before both, their sprint places 1 and 2 kept; the 15 pool items wait for the next sprint draw either way, 0 push-backs.
- Kept whole (T2, size rule): 1 rule, activation on first trigger, in area 15 (`carat/use_cases/plugins/plugin_registry.rb:221`, `carat/use_cases/plugins/plugin_host.rb:108`), its call in area 4 (`carat/adapters/editor_assembly.rb:469`) and area 16 tested through it; the brief fixes exactly 1 exception line, so a split would need a second exemption.
- Estimated medium, no size up (T2): plugin host rows git-signs-transport 741,002 in 43.0 min, lsp-container-b 1,004,078 in 100.0, git-signs-status-a 1,124,717 in 104.0 under 1,200,000; of the lane's last 2, only vim-folds-a went over (1,678,269), vim-line-commands-b 893,872 under.
- 0 `tools/rules.sh` edits (T2): the template `tools/new.sh` and `editor_assembly.rb` match TOOLS_RE (`tools/rules.sh:97`) as they are; nothing in the brief edits its patterns.
- Retro, overrun, and merge notes of git-signs-transport (6, 7, 8) and vim-line-commands-b (5 to 9) to this change's backlog file (T1 pipeline): 7 pipeline entries and 2 code entries; the backlog lane's queue, which holds `plan-skip-placed`, `merge-cap-ci-wait`, and `package-advisory-edit`, is barred by this brief.
