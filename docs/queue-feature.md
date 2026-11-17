# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 13

Drained: `palette-narrow` and `bar-colors` delivered; Sprint 14's features come from the pool at the sprint's close.

## Pool

1. `lsp-container-c` (T2 user request, estimated small): a `language.NAME.lsp.root` line whose root is relative or holds `.` or `..` is kept unreported (`carat/domain/config.rb:218`). Backlog: "### A language.NAME.lsp.root line whose root is not a root is kept without a report".
2. `markdown-reading-d` (T2 user request, estimated medium): headings, framed code blocks, rules, list gaps. Backlog: "### MarkdownText flow_key copies block's scan and keeps a dead indent cap", "### An indented code block inside a quote still flows into one quote row".
3. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start): Unstaged, Staged, Recent.
4. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics; `:grep :make :cnext :copen`.
5. `git-push-pull`, `git-diff-blame`, `language-any` (T2 user request, estimated medium each).
6. `vim-macros-marks`, `vim-case-increment` (T2 user request, estimated medium each).
7. `vim-line-commands`, `vim-folds` (T2 user request, estimated medium each, pushed back 2, S14).
8. `plugin-protocol-a`, `formatting`, `ux-pass-2` (T5, T5 roadmap 14, T2; estimated medium each, pushed back 1, S14): protocol a takes "## The plugin API cannot read or set the visual selection", "## Plugins cannot highlight ranges or add virtual text".
9. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5; estimated medium each, S15).
10. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; `test/lint.rb:255`. Backlog: both "### docs/spinel-notes.md:47:" entries.
11. `dogfooding`, `ux-fixes-b` (T2 user request, estimated medium each, S15).
12. `claude-bridge`, `claude-workflow` (T2 ideas to confirm, estimated large each, not before S15).
13. `markdown-preview` (T2, estimated medium), `mermaid-flowchart` (estimated large), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4).
14. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
15. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
16. `ex-global-commands` (T5 Neovim, estimated medium): "## The ex commands a global most often runs besides :s and :d".
17. `bidi-controls` (T3 security Lows, estimated small, pushed back 11); `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`, "### An untrusted project .caratrc may bind keys to destructive actions".
18. `insert-copy`, `bench-scenarios` (T4, estimated small each): "### make bench without SCENARIOS skips four scenarios".

## Decisions

- Security first clear (T0): no review.periodic note in pending palette-narrow or check-parallel; palette-narrow security high=0 medium=0 at 601b3bdd73e2; check-parallel medium=1 blocking=0 at acddfbbe0081 (below confidence 8, in tools, not this change).
- `bar-colors` delivered as written (T2 user now-request, Sprint 13 item 1 at 5e4d01f, the user's brief): removed; Sprint 13's feature lane drained to 0 items, the pool unchanged.
- No split (T2): 2 testable parts (accents on PANEL 7 at `carat/domain/themes.rb:212`, counts at `carat/adapters/status_bar.rb:243`) in one test file, under the split rule's 3; no `tools/rules.sh` edit.
- Estimate medium: last 10 feature rows 757,631 to 1,902,958 total, all medium; UI fixes ux-fixes-a 894,511 in 54 min and palette-narrow 736,843 in 51.2 min; the last two, lsp-container-b 1,004,078 and palette-narrow 736,843, under 1,200,000, so no size up.
- Quality first pass 67/132 overall, quality:0 in 4 of the last 10 feature rows: the acceptance names `test/domain_theme.rb` for both parts.
- Retro notes palette-narrow 3 and 4, check-parallel 8 to 10 (T1 pipeline: merge 69,031 of 304,750 output on a first-pass CI, check 40,656 for a pass, 4 of 7 advisories dropped): backlog lane, not this one, so entries in this plan's `backlog.md`.
- No overrun note: palette-narrow 736,843 in 51.2 min and check-parallel 849,706 in 44.1 min, both under medium 1,200,000.
- Quality-advisory notes palette-narrow 1 and 2, check-parallel 1 to 7 are handled already (quality-* notes).
