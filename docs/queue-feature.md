# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 13

1. `lsp-container-b` (T2 user request, feature, estimated medium, pushed back 2): part b of `lsp-container` (#171). Quit and :LspRestart may end more than the server carat started; `command?` (`carat/adapters/json_rpc_language_gateway.rb:318`) runs each idle tick while a filetype has no server and scans about 760 configuration lines twice (`root_line`, `:341`). Fix outline: end only the process carat spawned; settle a language's command once, as `trusted?` keeps its answer. Accepted when a test shows quit and :LspRestart ending only the server and an idle tick with no server reading no configuration line, allocations held. Backlog: "### The language server gateway rescans every configuration line for a rooted command on each idle tick".
2. `palette-narrow` (T2 user now-request regression, feature, estimated medium): below about 14 cells of float a row shows only its key, `label_room` being `width - KEY_WIDTH` (`carat/use_cases/discovery/follow_palette.rb:166`); `styles` never reads `cut` (`:187`, call `:144`); `pad` adds one space per pass (`:296`); `docs/codebase-map.md:169` names DisplayWidth.fit. Fix outline: room for a label at the narrowest width, `cut` read or dropped, one padding step, the map entry corrected. Accepted when a table row at the smallest screen shows a label. Backlog: "### Palette rows below about 14 cells show only the key", "### FollowPalette#styles never reads its cut parameter", "### The palette's pad appends one space per loop pass", "### The follow_palette map entry names DisplayWidth.fit".
3. `bar-colors` (T2 user now-request, feature, estimated medium): at 16 colors the lsp accents 3 and 2 on PANEL 7 read near 1.5:1 (`carat/domain/themes.rb:212`); the diagnostics counts draw on NONE (`carat/adapters/status_bar.rb:243`), not the bar. Fix outline: accents readable on the bar, counts on its background. Accepted when `test/domain_theme.rb` asserts both. Backlog: "### The lsp accents at 16 colors read poorly on the light gray bar", "### The status bar's diagnostics counts draw on the terminal's background".

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

- Security first clear (T0): sprint-12 review security Low (5) only, sweep pass high=0 medium=0 low=3 (6, 5, 4), none at 8, none disputed.
- Sprint 13: 3 features, 2 backlog; `lsp-container-b`, `palette-narrow`, `bar-colors` (T2, UI now-requests first by goal 1), pool 1 to 3 in order.
- Estimate medium for all three: no feature row of the last 10 under small's 500,000 (757,631 lowest); markdown-reading-c 1,902,958/117 over 1,200,000, git-signs-status-b 757,631 under, so not two over.
- `lsp-container-b` takes lsp-container quality advisory 2 (idle tick, about 760 lines twice), 2 parts; the not-a-root report (advisory 4) is `lsp-container-c`, a third part kept apart by the split rule.
- Sprint-12 notes 10 and sweep 34 (markdown_text.rb:160, :176) fold into `markdown-reading-d`, the same file.
- S13 tags of `vim-line-commands`, `vim-folds` (now 2), `plugin-protocol-a`, `formatting`, `ux-pass-2` move to S14: 3 T2 UI now-requests go first.
- Sweep Low (4) `config.rb:236` folds into `project-config-guards` (T3), its domain; sweep note 31 into `bench-scenarios`.
