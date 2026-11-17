# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 14

Drained: the lane's 3 features of Sprint 14 delivered, 0 left; `/sprint` draws Sprint 15 from the pool.

## Pool

1. `vim-line-commands-b`, `vim-folds` (T2 user request, estimated medium each; folds pushed back 3, reason: part a goes first as `:g` needs it): b takes `:j`, `:>`, `:<`, `:normal`, and "## The ex commands a global most often runs besides :s and :d".
2. `markdown-reading-e` (T2 user request, estimated medium): rules and list gaps in the reading view.
3. `git-panel` plugin (T2 user request, estimated large, pushed back 2, split at its start): Unstaged, Staged, Recent; after backlog `git-signs-transport`, which puts git's guards, spelled 3 times (`carat/plugins/git_signs/plugin.rb:27`, `:28`, `:42`), in one place.
4. `ux-pass-2` (T2 user now-request, estimated medium, pushed back 2, reason: no item list recorded beyond its name; drawn once the user names it).
5. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics; `:grep :make :cnext :copen`.
6. `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `vim-case-increment` (T2 user request, estimated medium each).
7. `spinel-workarounds` (T2 user request, estimated medium, pushed back 6, reason: no user-visible effect, goals 1 and 2 first): `json.rb:72`; `test/lint.rb:255`. Backlog: both "### docs/spinel-notes.md:47:" entries.
8. `plugin-protocol-a`, `formatting` (T5, T5 roadmap 14; estimated medium each, pushed back 2): protocol a takes "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
9. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5), `dogfooding`, `ux-fixes-b` (T2 user request) (estimated medium each, S15).
10. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each, not before S15).
11. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4).
12. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
13. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
14. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, "### An untrusted project .caratrc may bind keys to destructive actions".
15. `insert-copy`, `bench-scenarios` (T4, estimated small each): "### make bench without SCENARIOS skips four scenarios".

## Decisions

- Security first clear (T0): no `review.periodic-*` in the pending `markdown-reading-d` or `tab-close-b` run states; sprint-13 security Medium (6) `tools/run_state.sh:639` is below confidence 8.
- `vim-line-commands-a` delivered as written and removed (T2 user request, Sprint 14 item 1, pushed back 2): the brief at c451abd5d6d6; the lane's Sprint 14 drained, 0 of 3 features left.
- `vim-line-commands-a` estimated medium (T2): nearest row `buffer-global` (`:g`, same ex area) 1,231,942 total in 76.6 min, estimated medium; last-10 feature median 848,831 under medium's 1,200,000.
- No size up (T2): bar-colors 879,991 and lsp-container-c 816,907, the last two feature rows, under 1,200,000; pending markdown-reading-d 848,371 in 55.7 min too.
- `vim-line-commands-a` not split (T2): 2 testable parts (`:m`, `:t`/`:co`) in 1 map area, below the split rule's 3; already part a of 2.
- No merge-gate edit (T2): the brief names no `tools/rules.sh` change, 0 pattern edits.
- `markdown-reading-d` retro notes 4 and 5 (T1 pipeline, backlog lane): gates_failed 2 and package 22 calls to `review-demotion`, checker 35,360 output (13.0%) to `check-skip`; entries in this plan's backlog.md, `docs/queue-backlog.md` untouched by the brief.
- `markdown-reading-d` notes 1 to 3 are handled already (quality-* notes); `tab-close-b` notes 4 to 7 were placed by the backlog lane's `merge-record-check` plan.
- Pool order kept (T2 before T3 to T5): 0 items moved; `vim-line-commands-b` and `vim-folds` lead Sprint 15's draw.
