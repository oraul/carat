# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 13

1. `palette-narrow` (T2 user now-request regression, feature, estimated medium): below about 14 cells of float a row shows only its key, `label_room` being `width - KEY_WIDTH` (`carat/use_cases/discovery/follow_palette.rb:166`); `styles` never reads `cut` (`:187`, call `:144`); `pad` adds one space per pass (`:296`); `docs/codebase-map.md:169` names DisplayWidth.fit. Fix outline: room for a label at the narrowest width, `cut` read or dropped, one padding step, the map entry corrected. Accepted when a table row at the smallest screen shows a label. Backlog: "### Palette rows below about 14 cells show only the key", "### FollowPalette#styles never reads its cut parameter", "### The palette's pad appends one space per loop pass", "### The follow_palette map entry names DisplayWidth.fit".
2. `bar-colors` (T2 user now-request, feature, estimated medium): at 16 colors the lsp accents 3 and 2 on PANEL 7 read near 1.5:1 (`carat/domain/themes.rb:212`); the diagnostics counts draw on NONE (`carat/adapters/status_bar.rb:243`), not the bar. Fix outline: accents readable on the bar, counts on its background. Accepted when `test/domain_theme.rb` asserts both. Backlog: "### The lsp accents at 16 colors read poorly on the light gray bar", "### The status bar's diagnostics counts draw on the terminal's background".

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

- Security first clear (T0): sprint-12 security Low (5) only, sweep high=0 medium=0; no pending run holds a review.periodic note; nothing at 8, nothing disputed.
- `lsp-container-b` delivered as written (T2 user request, Sprint 13 item 1, pushed back 2): 2 parts, under the split rule's 3; removed, `palette-narrow` and `bar-colors` follow in order.
- Estimate medium: last 10 feature rows 757,631 to 1,902,958 total, all medium; part a `lsp-container` 802,117 in 47.0 min; of the last two only markdown-reading-c (1,902,958) went over, so no size up.
- `lsp-container-c` stays pool 1 (T2, small): the gateway's third part, kept apart by the split rule.
- sprint-12-records retro notes 4 (bench 15,099 of 127,367 output tokens over 3 docs-only records runs) and 5 (groom hand edits 2 of 3 records runs, 3 of 3 advisories on its output) are T1 pipeline: backlog lane, not this one, so to this plan's `backlog.md`.
- Sprint-12-records quality-advisory notes 1 to 3 are handled already (quality-* notes); no other pending note.
