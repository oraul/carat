# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 16

The user-approved exception: `plugin-lazy-activate` (T2 user request, estimated medium, beyond the sprint, the user-approved exception), Sprint 16's one exemption.

1. `vim-folds-b` (T2 user request, correctness of part a, estimated medium, part b of 3, pushed back 1, reason: the user-approved exception goes first): the sprint-15 review found shipped folds wrong: the crossing test of `carat/domain/folds.rb:85` matches a fold starting on the new fold's first row, so `zf3jzozfj` on rows 0 to 3 leaves [0,3] twice where Vim nests [0,1]; `Buffer#revert_to` (`carat/domain/buffer.rb:676`) rolls back a failed plugin edit but not the folds its splice shifted (`:720`); in Insert mode the cursor's closed fold stays closed (`carat/use_cases/arrange_view.rb:60`, `frame_presenter.rb:734`, `:829`), so i, a, I, A edit its hidden first line with the cursor at column 0; a closed split or tab page keeps its folds tracked and shifted on every edit (`carat/domain/layout.rb:229`, `carat/domain/buffer_list.rb:370`). Fix outline: folds nest, revert, and open as Neovim's. Accepted when rows show `zf3jzozfj` nesting, `[[2,6],[2,3]]` in `test/domain_folds.rb`, a reverted plugin edit leaving folds as before, `zfjiX` with the fold open and X on row 0, and 1 fold list after `zfj<C-w>s<C-w>c`. Backlog: "### A closed window's folds stay tracked and are shifted on every edit", "### Layout#close frees a window without untracking its folds", "### Closing a split or a tab never untracks its windows' folds".

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

- Security first clear (T0): pending plugin-lazy-activate at c2b35c53a064 and sprint-size-six at 2d4d9a8ffa16, each security high 0, medium 0, low 0, blocking 0, and 0 `review.periodic` findings; nothing in `security_first`.
- `tab-close-d` delivered as written and removed (T2 user-reported bug): Sprint 16 item 1 at 94155c0, after the exception merged at 94155c0df530; its 2 backlog headings close with it.
- Estimated medium, no size up (T2): tab-close-c 830,180 in 54.5 min, vim-line-commands-b 893,872 in 61.1; of the lane's last 2, plugin-lazy-activate 1,245,262 in 95.1 went over 1,200,000 (its overrun note 9), vim-line-commands-b under.
- Kept whole (T2, size rule): 2 parts sharing one host request, `open_as_tab` (`carat/use_cases/plugins/window_requests.rb:211`, its no-file-window branch `:214`), under 3.
- Sprint-16 closes at 5 (T1 rule): secret-patterns, git-signs-transport, vim-line-commands-b, sprint-size-six count 4, plugin-lazy-activate exempt (SPRINT_EXCEPTIONS=1, `tools/run_state.sh:413`); the next merge of either lane is the fifth, so `vim-folds-b` likely carries into sprint-17's draw, 0 push-backs now.
- Pool unchanged, 0 push-backs (T2): the 15 pool items wait for sprint-17's draw.
- 0 `tools/rules.sh` edits (T2): the brief edits no gate pattern.
- Retro notes of plugin-lazy-activate (T1 pipeline): 11 (quality 85/153 first pass) and 12 (scout 16.6 percent of output) to this change's backlog file, the backlog lane's queue barred by this brief; 10 dropped, the fixed-6 check-pass line already queued as backlog `records-budget-scope`; quality notes of both runs handled already.
