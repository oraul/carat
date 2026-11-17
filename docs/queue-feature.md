# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 12

Feature lane complete: `markdown-reading-c` merged (#169); `lsp-container` part a, the sprint's fifth counted change, delivered now; part b `lsp-container-b` waits in the pool.

## Pool

1. `lsp-container-b` (T2 user request, feature, estimated small): part b of `lsp-container`, which ran 2 push-backs; a root's server (`config/default.caratrc:749`) now runs per root, but quit and :LspRestart may still end more than the server carat started. Accepted when quit and :LspRestart end only the server process. Backlog: none.
2. `palette-narrow` (T2 user now-request regression, estimated small): below about 14 cells of float a palette row shows only its key, `label_room` being `width - KEY_WIDTH` (`carat/use_cases/discovery/follow_palette.rb:166`); `styles` never reads `cut` (`:187`, call `:144`); `pad` adds one space per pass (`:296`); `docs/codebase-map.md:169` names DisplayWidth.fit. Accepted when a table row at the smallest screen shows a label. Backlog: "### Palette rows below about 14 cells show only the key", "### FollowPalette#styles never reads its cut parameter", "### The palette's pad appends one space per loop pass", "### The follow_palette map entry names DisplayWidth.fit".
3. `bar-colors` (T2 user now-request, estimated small): 16-color lsp accents 3 and 2 on PANEL 7 read near 1.5:1 (`carat/domain/themes.rb:212`); diagnostics counts draw on NONE (`carat/adapters/status_bar.rb:243`). Accepted when `test/domain_theme.rb` asserts both. Backlog: "### The lsp accents at 16 colors read poorly on the light gray bar", "### The status bar's diagnostics counts draw on the terminal's background".
4. `markdown-reading-d` (T2 user request, estimated medium, after markdown-reading-c): headings, framed code blocks, rules, list gaps.
5. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start): Unstaged, Staged, Recent; confirm destructive.
6. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics list; rubocop state; `:grep :make :cnext :copen`.
7. `git-push-pull` (T2 user request, estimated medium): `P` asks, never force; `F` pulls.
8. `git-diff-blame` (T2 user request, estimated medium): `=` diffs; a blame line.
9. `language-any` (T2 user request, estimated medium).
10. `vim-macros-marks`, `vim-case-increment` (T2 user request, estimated medium each).
11. `vim-line-commands`, `vim-folds` (T2 user request, estimated medium each, pushed back 1, S12 to S13).
12. `plugin-protocol-a`, `formatting`, `ux-pass-2` (T5, T5 roadmap 14, T2; estimated medium each, S13).
13. `plugin-protocol-b`, `release-build`, `sample-plugin` (T5; estimated medium each, S14).
14. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; `test/lint.rb:255`; `docs/spinel-notes.md:47`. Backlog: "### docs/spinel-notes.md:47: the Spinel regression bullet mixes terms, stale advice, and dated figures".
15. `dogfooding` (T2 user request, estimated medium, S15).
16. `ux-fixes-b` (T2 user now-request, estimated medium, split at its start, S15): ux-pass findings 1, 2, 4, 6, 7, 8, 9, 11.
17. `claude-bridge`, `claude-workflow` (T2 user ideas to confirm, estimated large each, split, not before S15).
18. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
19. `mermaid-flowchart` (estimated large, split at its start), `mermaid-sequence` (estimated medium) (T2 user now-request, pushed back 4).
20. `finder-grep`, `definition-tab`, `finder-pickers`, `filetype-rules` (T5 user request, estimated medium each, pushed back 6).
21. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
22. `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
23. `ex-global-commands` (T5 Neovim support, estimated medium): `:m :t :normal :p` under `:g` answer E492. Backlog: "## The ex commands a global most often runs besides :s and :d".
24. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
25. `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`.
26. `insert-copy` (T4, estimated small, pushed back 12).
27. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`, `:22`; sweep note 30.

## Guide

- S9 to S15: three features, two fixes each by the sprint tags; S15 holds `dogfooding` and two features S7 to S14 reveal.
- Diagnostics come only from a language server; no built-in checker.
- Dropped: carat drawing its own glyphs (`nerd` stays an option).

## Decisions

- Security first clear (T0): markdown-reading-c and planner-split-rule security high=0 medium=0 low=0; no periodic review pending; sprint-11 Medium (4), Low (3) under 8, none disputed.
- `lsp-container` (T2 user request, pushed back 2) delivered split by the user's rule: 3 independently testable parts; part a (root command, project line refused) now, the sprint's fifth counted change.
- `lsp-container-b` (T2 user request, small) placed pool 1, ahead of `palette-narrow`: the rest of a 2-push-back item, one more reaching aging's 3.
- Estimate medium: no feature row of the last 10 under small's 500,000/25 min (757,631/88 to 1,284,000/169); markdown-reading-c 1,902,958/117 over 1,200,000, git-signs-status-b 757,631 under, so not two over; one part left, no `tools/rules.sh` edit.
- Overruns: markdown-reading-c check 245,802 to 341,171 output against 200,000 (notes 8, 16, 17); windows-buffers-tidy 1,373,899 total (note 21); planner-split-rule merge 14 calls against 12 (note 9).
- Retro notes markdown-reading-c 18 to 20 and planner-split-rule 5 to 7 (T1 pipeline) go to this change's findings for the backlog lane, which this brief leaves untouched.
- Quality notes of both runs handled already; their late findings go by history.
