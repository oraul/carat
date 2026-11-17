# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 14

1. `vim-line-commands-a` (T2 user request, estimated medium, pushed back 2, part a of 2): `:m` and `:t` (`:co`) do not exist (`docs/compatibility.md:384`), so `:g` cannot move or copy lines. Fix outline: two ex commands registered in the order of `docs/compatibility.md`, each with a range and a target address, one undo step each. Accepted when their compatibility rows and a table-driven test show `:2m0`, `:1,3m$`, `:t.`, `:co0`, and `:g/x/m0` as Neovim gives them, `E134` for a move into its own range, `E16` for a bad address, and line 384's sentence updated.

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

- Security first clear (T0): no `review.periodic-*` in the pending `lsp-container-c` or `sprint-13-records` run states; sprint-13 security Medium (6) `tools/run_state.sh:639` is below confidence 8.
- `markdown-reading-d` delivered and removed (T2 user request, Sprint 14 item 1): delivered as written at 49d305d8b4bc, the user's reading-view parts 2 of 4.
- `markdown-reading-d` estimated medium (T2): same area as markdown-reading a 1,035,751, b 817,671, c 1,902,958 total, median 1,035,751 under medium's 1,200,000.
- No size up (T2): bar-colors 879,991 and palette-narrow 736,843, the last two feature rows, under medium's 1,200,000; pending lsp-container-c 816,907 too.
- `markdown-reading-d` not split (T2): 2 testable parts in 1 map area, below the split rule's 3: the one marker scan (its 3 entries, one fix) and the heading and framed-code styles.
- Sprint 14 keeps 3 features, 2 backlog (T2 sprint rule): `vim-line-commands-a` left in this lane; the backlog lane's `tab-close-b` and `merge-record-check` untouched by this plan.
- `lsp-container-c` retro notes 4 to 6 (T1 pipeline, backlog lane): merge 30 of 119 calls to `merge-gate-integrity`, 3 of 3 advisories dropped to `review-demotion`, scout and areas 18.9% of output to `scout-value`; entries in this plan's backlog.md.
- `lsp-container-c` notes 1 to 3 and `sprint-13-records` notes 1 to 5 are handled already (quality-* notes); `sprint-13-records` notes 6 and 7 placed by the last plan.
