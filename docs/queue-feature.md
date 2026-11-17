# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 11

1. `git-signs-status-b` (T2 user request, part b, feature, estimated medium, S11 by the user): no sign shows a line added, changed, or deleted. Part a runs two captures on the editor thread per buffer_open, buffer_save, window_focus (`plugin.rb:43`, `:60`), up to 4 s (sprint-9 Low (5); sweep note 34: each window switch waits on git); a diff capture adds a third. Accepted when a canned git shows each sign kind on its lines, a focus change with HEAD and the file unchanged runs no git, a timed-out capture stalls no later event, allocations held. Backlog: "### git_signs runs git synchronously on the editor thread".
2. `markdown-reading-c` (T2 user now-request, feature, estimated small, S11, back from the pool): at 60 columns paragraphs and quotes show ragged (`carat/domain/markdown_text.rb`). Folds: a pipe line right after a table stays a row (`:177`, sprint-10 note 6), the table row-cap overrun (`:182`), `format_docs.rb:33` bool literals. Accepted when a two-line paragraph and quote each flow as one at 60 columns, allocations held. Backlog: "### MarkdownText.parse overruns its row cap with a table".

## Pool

1. `lsp-container` (T2 user request, feature, estimated medium, pushed back 2, S12): only `language.<name>.lsp` (`config/default.caratrc:749`) names a server. A user-file line `language.<name>.lsp.root ROOT COMMAND...` runs that command as written, no shell, as the server under ROOT; carat ends only its server process; a project's `.caratrc` names no program. Accepted when a test shows the root's command under ROOT, the default elsewhere, the project file's line refused, quit and :LspRestart ending only the server.
2. `markdown-reading-d` (T2 user request, feature, estimated medium, after markdown-reading-c): headings, framed code blocks, rules, list gaps.
3. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start): Unstaged, Staged, Recent; `s`, `u`, `c`, `?`; confirm destructive.
4. `lint-panel` (T2 user request, estimated large, split at its start): diagnostics list; rubocop state; `:grep :make :cnext :copen`.
5. `git-push-pull` (T2 user request, estimated medium): `P` asks before a push, never force; `F` pulls.
6. `git-diff-blame` (T2 user request, estimated medium): `=` diffs the file; a blame line.
7. `language-any` (T2 user request, estimated medium): `language.<name>.lsp` lines.
8. `vim-macros-marks` (T2 user request, estimated medium).
9. `vim-case-increment` (T2 user request, estimated medium).
10. `vim-line-commands` (T2 user request, estimated medium, S12).
11. `vim-folds` (T2 user request, estimated medium, S12).
12. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
13. `formatting` (T5 roadmap 14, estimated medium, S13).
14. `ux-pass-2` (T2 user now-request, estimated medium, S13).
15. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S14).
16. `release-build` (T5 roadmap 15, estimated medium, S14).
17. `sample-plugin` (T5 user-scheduled, estimated medium, S14).
18. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; `test/lint.rb:255`; `docs/spinel-notes.md:47`.
19. `dogfooding` (T2 user request, estimated medium, S15).
20. `ux-fixes-b` (T2 user now-request, estimated medium, split at its start, S15): ux-pass findings 1, 2, 4, 6, 7, 8, 9, 11.
21. `claude-bridge` (T2 user request, estimated large, split at its start, idea, the user to confirm, not before S15): carat as an IDE a Claude Code session connects to.
22. `claude-workflow` (T2 user request, estimated large, split at its start, idea, the user to confirm, after claude-bridge): a keyboard-only guided loop.
23. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
24. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
25. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
26. `finder-grep` (T5 user request, estimated medium, pushed back 6).
27. `definition-tab` (T5 user request, estimated medium, pushed back 6).
28. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
29. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
30. `filetype-rules` (T5 user request, estimated medium, pushed back 6).
31. `syntax-definitions`, `syntax-forms`, `syntax-embedded` (T5 user request, estimated medium each, pushed back 6).
32. `javascript-syntax`, `html-syntax` (T5 user request, estimated medium each, pushed back 6).
33. `ex-global-commands` (T5 Neovim support, estimated medium): `:m`, `:t`, `:normal`, `:p` under `:g` answer E492. Backlog: "## The ex commands a global most often runs besides :s and :d".
34. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
35. `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`.
36. `insert-copy` (T4, estimated small, pushed back 12).
37. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`, `:22`; sweep note 30.

## Guide

The user's guide, security first:

- S9 to S15: three features, two fixes each by the sprint tags; `gate-object-pin` first if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- A language's diagnostics come from its language server; carat adds no built-in checkers; refuse an item proposing one.
- Pipeline items: `review-demotion` and `scout-value` first (sprint-9 throughput).
- Dropped: carat drawing its own glyphs (`nerd` stays an option).

## Decisions

- Security first clear (T0): no open High or Medium at 8+; sweep High (9) `git_signs/plugin.rb:23` fixed by f29f956 (#160); review-pipeline-a security high=0 medium=0 at 7c4b5907ab82.
- `ux-fixes-a` (T2 user now-request) delivered as Sprint 11 item 1 and removed: 3 fixes plus 1 entry heading, under the about-four split line; no `tools/rules.sh` edit.
- Estimate medium: last 10 feature rows 775,758 to 1,284,000 total, 51 to 169 min; palette-rows (same palette file) 1,284,000 with 2 rework, the overrun risk.
- Sprint 11 keeps `git-signs-status-b` and `markdown-reading-c` (T2, S11 by the user); its 3 feature slots counted with `ux-fixes-a`, none drawn; pool order unchanged, no push-back.
- Header `insert` 26.0: the last feature row (git-signs-trust, #160) records insert=26.0, not 32.0 (sprint-10-records quality note 2).
- Handed `ProcessPort` row finding (`docs/architecture.md:213`, `capture(argv)` since #160): T6 docs drift, appended by the contributor per the brief; not queued.
- Pending retro notes: review-pipeline-a 5 to 8 placed by the backlog lane's plan; sprint-10-records note 5 shares note 3's cause, kept by `plan-apply-guard`; note 4 (bench 4,848 of 52,240 output) to `backlog.md`.
