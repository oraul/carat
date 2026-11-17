# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 13

1. `bar-colors` (T2 user now-request, feature, estimated medium): at 16 colors the lsp accents 3 and 2 on PANEL 7 read near 1.5:1 (`carat/domain/themes.rb:212`); the diagnostics counts draw on NONE (`carat/adapters/status_bar.rb:243`), not the bar. Fix outline: accents readable on the bar, counts on its background. Accepted when `test/domain_theme.rb` asserts both. Backlog: "### The lsp accents at 16 colors read poorly on the light gray bar", "### The status bar's diagnostics counts draw on the terminal's background".

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

- Security first clear (T0): lsp-container-b security pass high=0 medium=0 at b89f709acdc9, sprint-security high=0 medium=0 low=1 at 1a344eabf30c; no pending run holds a review.periodic note.
- `palette-narrow` delivered as written (T2 user now-request regression, Sprint 13 item 1 at c848525, the user's brief): removed; `bar-colors` is now Sprint 13 item 1, the pool unchanged.
- No split (T2): 4 headings in one file and one map line hold one behavior check (a label at the smallest screen); `cut`, `pad`, and the map line are tidy-ups, under the split rule's 3 independently testable parts.
- Estimate medium: last 10 feature rows 757,631 to 1,902,958 total, all medium; UI fix ux-fixes-a 894,511 in 54 min; the last two, lsp-container 802,117 and lsp-container-b 1,004,078, stayed under 1,200,000, so no size up.
- Overrun noted (T1): lsp-container-b note 10, 229,659 output against the medium 200,000 after one quality fix round (implement 153,294 of 264,142); its total 1,004,078 stayed under budget.
- Quality first pass 66/130 overall and quality:0 in 4 of the last 10 feature rows plus lsp-container-b: this item's acceptance names its test.
- Retro notes lsp-container-b 11 to 13 and sprint-security 7 to 9 (T1 pipeline, scout 19.2%, 59 total per output): backlog lane, not this one, so entries in this plan's `backlog.md`.
- Overrun notes lsp-container-b 14 and sprint-security 10 (sprint-12-records 2,147,268 over small 500,000) dropped: already in its history row and the lsp-container-b plan.
- Quality-advisory notes lsp-container-b 1 to 9 and sprint-security 1 to 6 are handled already (quality-* notes).
