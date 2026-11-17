# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 15

Drained: the lane's 3 features of Sprint 15 delivered, 0 left; `/sprint` draws Sprint 16 from the pool.

## Pool

1. `vim-line-commands-b` (T2 user request, estimated medium, pushed back 1, reason: a regression and two aged items took Sprint 15; `:normal` and `:p` split to c): `:j`, `:>`, `:<`; with the line-command tidy of sprint-14 (`move_command_handler.rb:81`, `copy_command_handler.rb:67`, REPORT 3 times, E477 5 times, `ex_range.rb:67`, map `docs/codebase-map.md:402`).
2. `tab-close-d` (T2 user-reported bug, estimated small): the explorer's t with no file window opens a tab page holding only the tree (`window_requests.rb:211`); the finder's tab pick opens a tab page under `option.gt buffers` (`carat/plugins/finder/plugin.rb:327`); explorer comment `:253`.
3. `markdown-reading-e` (T2 user request, estimated medium, pushed back 1): rules and list gaps in the reading view; parse scans markers twice per line; `format_docs.rb:36` bare framed flag.
4. `vim-folds-b`, `vim-line-commands-c` (T2 user request, estimated medium each): b takes zR, zM, zj, zk, [z, ]z, `:fold`, `:foldopen`, `:foldclose` on part a's fold model; c takes `:normal`, `:p`, "## The ex commands a global most often runs besides :s and :d".
5. `git-panel` plugin (T2 user request, estimated large, pushed back 2, split at its start): Unstaged, Staged, Recent; after backlog `git-signs-transport`.
6. `ux-pass-2` (T2 user now-request, estimated medium, pushed back 2, reason: no item list beyond its name; drawn once the user names it).
7. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics; `:grep :make :cnext :copen`.
8. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `vim-case-increment` (T2 user request, estimated medium each).
9. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no user-visible effect): `json.rb:72`, `test/lint.rb:255`, the two spinel-notes entries.
10. `plugin-protocol-a`, `formatting` (T5 roadmap 14, estimated medium each, pushed back 2): selection and highlight requests.
11. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5), `dogfooding`, `ux-fixes-b` (T2 user request) (estimated medium each).
12. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each).
13. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4, reason: after the UI track).
14. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
15. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10, reason: after the UI track).
16. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, untrusted keymap lines; sweep `rc_config_gateway.rb:70` Low (3), `config.rb:204` trusted_roots.
17. `insert-copy`, `bench-scenarios` (T4, estimated small each): bench skips 4 scenarios (`bench/run.sh:69`).

## Decisions

- Security first clear (T0): ci-trust-gaps security pass high 0, medium 0, low 1 at 9e6738506a90, its Medium (8) fixed before merge 98291c9d75e4; ruby-structure-remove security high 0, medium 0, low 0 at 2a6d4a7ff860; 0 periodic findings in the 2 pending runs.
- `vim-folds-a` delivered as written and removed (T2 user request, pushed back 3): 0 fold rows in `docs/compatibility.md`; the only z keys bound are zt, zz, zb (`config/default.caratrc:183` to `:185`).
- Size medium, no size up (T2): the last ten feature rows average 946,912 total tokens, 9 of 10 under 1,200,000; the last two, tab-close-c 830,180 in 54.5 min and ruby-structure-remove 801,482 in 45.5 min, under budget.
- No further split (T2): already part a of 2; it reaches about 5 map areas (5, 6, 7, 11, 13), but the drawing and the j, k, and operator halves read one fold model, and the drawing alone lets j land on hidden lines, which Neovim never does; scouts cover at most 3 areas.
- Sprint 15 drained in the feature lane (T2): tab-close-c, ruby-structure-remove, and vim-folds-a are its 3 features; no pool item moves, 0 new push-backs.
- ruby-structure-remove retro note 2 to the findings file (T1 pipeline defect, backlog lane): docs-lint's path check failed its check on 2 removed paths its own queue item named, 1 rework round; this delivery keeps off `docs/queue-backlog.md`.
- ruby-structure-remove retro note 3 to the findings file (T1 efficiency, not a defect): scout 33,374 of 135,491 output tokens (24.6%) on a one-area removal; the sprint rule takes a pipeline change only for a defect.
- ci-trust-gaps notes 6 to 9 left to the backlog lane (T1): its run and its row are that lane's package step's.
- 0 `tools/rules.sh` edits (T1): the brief names fold keys, drawing, motions, and operators only.
