# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 15

1. `ruby-structure-remove` (T2 user request, estimated medium, pushed back 4, moved from the backlog lane): #147's unclosed-opener sign took a 100,000-line Ruby open from 22 to 116 ms and the user asked for its removal; it lives in carat/plugins/ruby/structure.rb (removed), `carat/plugins/ruby/plugin.rb:86` and `:111` (a whole-buffer rescan per normal-mode change), the tokenizer's opener state (`carat/plugins/ruby/tokenizer.rb:820`), test/editor_ruby_structure.rb (removed), `test/plugins_ruby.rb:145`, `README.md:124`, and `openspec/specs/ruby-syntax/spec.md`. Fix outline: remove the sign and its spec requirement, highlighting unchanged. Accepted when no structure sign is drawn, the open-ruby bench is at or under main's, the spec and README name no sign, highlighting snapshots are unchanged, and each entry below is closed or carried to the findings file. Backlog: "### Ruby structure sign goes stale after a buffer rename", "### Ruby plugin restates the filetype tables", "### Ruby structure editor test covers only insert mode", "### Ruby structure modifier table misses most jump words", "### Ruby tokenizer keeps the loop flag across a semicolon", "### Ruby structure check rescans the whole buffer per normal-mode change", "### README wording makes the structure sign sound conditional".
2. `vim-folds-a` (T2 user request, estimated medium, pushed back 3, part a of 2): carat has no folds: `docs/compatibility.md` holds 0 fold rows and zf, zo, zc, za, zd, zE do nothing. Fix outline: manual folds per window; a closed fold drawn as one row and passed by j and k as one line; an operator on a closed fold acting on all its lines; part b takes zR, zM, zj, zk, [z, ]z, `:fold`, `:foldopen`, `:foldclose`. Accepted when compatibility rows and a table-driven test show zfj leaving a closed 2-line fold drawn as one row, j passing it, zo, zc, za, zd, zE, and dd on a closed fold deleting its lines as Neovim does, the keys bound in `config/default.caratrc`, and `lh` and `j` held.

## Pool

1. `vim-line-commands-b` (T2 user request, estimated medium, pushed back 1, reason: a regression and two aged items took Sprint 15; `:normal` and `:p` split to c): `:j`, `:>`, `:<`; with the line-command tidy of sprint-14 (`move_command_handler.rb:81`, `copy_command_handler.rb:67`, REPORT 3 times, E477 5 times, `ex_range.rb:67`, map `docs/codebase-map.md:402`).
2. `tab-close-d` (T2 user-reported bug, estimated small): the explorer's t with no file window opens a tab page holding only the tree (`window_requests.rb:211`); the finder's tab pick opens a tab page under `option.gt buffers` (`carat/plugins/finder/plugin.rb:327`); explorer comment `:253`.
3. `markdown-reading-e` (T2 user request, estimated medium, pushed back 1): rules and list gaps in the reading view; parse scans markers twice per line; `format_docs.rb:36` bare framed flag.
4. `vim-folds-b`, `vim-line-commands-c` (T2 user request, estimated medium each): c takes `:normal`, `:p`, "## The ex commands a global most often runs besides :s and :d".
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

- Security first clear (T0): sprint-14-records security high 0, medium 0, low 0; sprint-14 review 1 Low (3) `tools/gates.sh:131`; 0 open High or Medium at confidence 8 or above.
- `tab-close-c` delivered as written and removed (T2 user-reported bug): sprint-14 quality `switch_buffer.rb:39`, 5 commands failing in a reading view, 0 reading-view tests, a regression of #181.
- Size medium, no size up, no split (T2): tab-close 1,038,200 in 81.6 min and tab-close-b 1,050,899 in 70.1 min under 1,200,000; last two feature rows 848,371 and 890,042 under; 2 parts, under 3.
- Sprint 15 keeps `ruby-structure-remove` and `vim-folds-a` (T2, pushed back 4 and 3), no pool draw: 2 features and 2 backlog left of its 5.
- sprint-14-records retro notes 3 and 4 left to the backlog lane (T1 pipeline): its row and `docs/queue-backlog.md` are that lane's, which this delivery does not touch.
- 0 `tools/rules.sh` edits (T1): the brief names `carat/` and `test/` files only.
