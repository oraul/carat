# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 12

1. `markdown-reading-c` (T2 user now-request, feature, estimated small, S11, carried): at 60 columns paragraphs and quotes show ragged (`carat/domain/markdown_text.rb`). Folds: a pipe line right after a table stays a row (`:177`, sprint-10 note 6), the table row-cap overrun (`:182`), `carat/use_cases/docs/format_docs.rb:33` bool literals. Accepted when a two-line paragraph and quote each flow as one at 60 columns, allocations held. Backlog: "### MarkdownText.parse overruns its row cap with a table".
2. `lsp-container` (T2 user request, feature, estimated medium, pushed back 2, S12): only `language.<name>.lsp` (`config/default.caratrc:749`) names a server. A user-file line `language.<name>.lsp.root ROOT COMMAND...` runs that command as written, no shell, as the server under ROOT; carat ends only its server process; a project's `.caratrc` names no program. Accepted when a test shows the root's command under ROOT, the default elsewhere, the project file's line refused, quit and :LspRestart ending only the server. Backlog: none.

## Pool

1. `palette-narrow` (T2 user now-request regression, estimated small): below about 14 cells of float a palette row shows only its key, `label_room` being `width - KEY_WIDTH` (`carat/use_cases/discovery/follow_palette.rb:166`); `styles` never reads `cut` (`:187`, call `:144`); `pad` adds one space per pass (`:296`); `docs/codebase-map.md:169` names DisplayWidth.fit. Accepted when a table row at the smallest screen shows a label. Backlog: "### Palette rows below about 14 cells show only the key", "### FollowPalette#styles never reads its cut parameter", "### The palette's pad appends one space per loop pass", "### The follow_palette map entry names DisplayWidth.fit".
2. `bar-colors` (T2 user now-request, estimated small): 16-color lsp accents 3 and 2 on PANEL 7 read near 1.5:1 (`carat/domain/themes.rb:212`); diagnostics counts draw on NONE (`carat/adapters/status_bar.rb:243`). Accepted when `test/domain_theme.rb` asserts both. Backlog: "### The lsp accents at 16 colors read poorly on the light gray bar", "### The status bar's diagnostics counts draw on the terminal's background".
3. `markdown-reading-d` (T2 user request, estimated medium, after markdown-reading-c): headings, framed code blocks, rules, list gaps.
4. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start): Unstaged, Staged, Recent; confirm destructive.
5. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics list; rubocop state; `:grep :make :cnext :copen`.
6. `git-push-pull` (T2 user request, estimated medium): `P` asks, never force; `F` pulls.
7. `git-diff-blame` (T2 user request, estimated medium): `=` diffs; a blame line.
8. `language-any` (T2 user request, estimated medium).
9. `vim-macros-marks`, `vim-case-increment` (T2 user request, estimated medium each).
10. `vim-line-commands`, `vim-folds` (T2 user request, estimated medium each, pushed back 1, S12 to S13).
11. `plugin-protocol-a`, `formatting`, `ux-pass-2` (T5, T5 roadmap 14, T2; estimated medium each, S13).
12. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5; estimated medium each, S14).
13. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; `test/lint.rb:255`; `docs/spinel-notes.md:47`. Backlog: "### docs/spinel-notes.md:47: the Spinel regression bullet mixes terms, stale advice, and dated figures".
14. `dogfooding` (T2 user request, estimated medium, S15).
15. `ux-fixes-b` (T2 user now-request, estimated medium, split at its start, S15): ux-pass findings 1, 2, 4, 6, 7, 8, 9, 11.
16. `claude-bridge`, `claude-workflow` (T2 user ideas to confirm, estimated large each, split, not before S15).
17. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
18. `mermaid-flowchart` (estimated large, split at its start), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4).
19. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules` (T5 user request, estimated medium each, pushed back 6).
20. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
21. `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
22. `ex-global-commands` (T5 Neovim support, estimated medium): `:m :t :normal :p` under `:g` answer E492. Backlog: "## The ex commands a global most often runs besides :s and :d".
23. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
24. `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`.
25. `insert-copy` (T4, estimated small, pushed back 12).
26. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`, `:22`; sweep note 30.

## Guide

- S9 to S15: three features, two fixes each by the sprint tags; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Diagnostics come only from a language server; no built-in checker.
- Dropped: carat drawing its own glyphs (`nerd` stays an option).

## Decisions

- Security first clear (T0): no periodic finding at 8 or above unfixed; sprint-11 Medium (4), Low (3) under 8, none disputed.
- `git-signs-status-b` (T2 user request, S11 by the user) delivered, removed from Sprint 12; `markdown-reading-c`, `lsp-container` (T2) stay, 2 features left.
- Estimated medium: git-signs-status-a 1,124,717 total, 104 min; last 10 feature rows 775,758 to 1,284,000, 51 to 169 min.
- Size check: 4 acceptance parts, within about four, not split; git-signs-status-a quality 0 first pass, rework 1.
- `git-signs-transport` (T3, Medium (4) below 8, `plugin.rb:27`) stays in the backlog lane; this change only matches BRANCH's arguments.
- sprint-11-records retro notes 8 (bench 3,791/7 calls), 9 (reviews 41.0% of output), 10 (groom 22 counted, 20 removed): T1 pipeline, left to the backlog lane's plan.
- Pool unchanged.
