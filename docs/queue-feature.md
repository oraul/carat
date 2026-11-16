# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 10

1. `markdown-reading-b` (T2 user now-request, feature, estimated medium): at 60 columns the reading view (`carat/domain/markdown_text.rb`) shows raw pipes, the separator row, ragged paragraphs and quotes. Outline: tables aligned in box borders (ascii under option.icons ascii), alignment markers honored, cells wrapped when narrow; paragraphs and quotes flowed to the measure. Folds: callers pass `carat/use_cases/docs/format_docs.rb:33` bare bool literals (sprint-9 note 12); `carat/use_cases/docs/toggle_reading.rb:86` copies a line over the 262,144-byte cap whole; `docs/codebase-map.md:633` omits ToggleReading. Accepted when snapshots show a three-column aligned table at 100 and 60 columns, a two-line paragraph and quote flowed as one, no box cell under ascii, an over-cap line read only to the cap, allocations held. Backlog: "### ToggleReading copies one over-cap line whole", "### The FormatDocs map entry omits ToggleReading".

## Pool

1. `git-signs-status-b` (T2 user request, part b, feature, estimated medium, S11 by the user): no sign shows a line added, changed, or deleted. Part a (#148) runs two captures on the editor thread per buffer_open, buffer_save, window_focus (`carat/plugins/git_signs/plugin.rb:43`, `:60`), up to 4 s (sprint-9 Low (5)), and its `rev-list` (`plugin.rb:23`) can lazy-fetch from an untrusted `.git`'s promisor remote, running its command (Medium (6)); a diff capture adds a third. Outline: the three signs, refreshes bounded. Accepted when a canned git shows each sign kind on its lines, a focus change with HEAD and the file unchanged runs no git, a timed-out capture stalls no later event, a case's partial clone with a command promisor runs no command, allocations held. Backlog: "### git_signs rev-list can lazy-fetch from a promisor remote in an untrusted .git (security Medium, confidence 6)", "### git_signs runs git synchronously on the editor thread".
2. `lsp-container` (T2 user request, feature, estimated medium, pushed back 1, S11 by the user): only `language.<name>.lsp` (`config/default.caratrc:749`) names a server. Outline: a user-file line `language.<name>.lsp.root ROOT COMMAND...` runs that command as written, no shell, as the server under ROOT, elsewhere `language.<name>.lsp`; no path translation; carat never manages a container, ending only its server process; a project's `.caratrc` names no program. Accepted when a test shows the root's command under ROOT, the default elsewhere, the project file's line refused, quit and :LspRestart ending only the server. Backlog: none.
3. `ux-fixes-a` (T2 user now-request, estimated medium, S11 by the user): ux-pass findings 3, 5, 10: the status-bar hole, the finder dropping its query, the palette's internal names.
4. `markdown-reading-c` (T2 user request, feature, estimated medium, after markdown-reading-b): headings, framed code blocks, rules, list gaps.
5. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start, S11+): Unstaged, Staged, Recent; `s`, `u`, `c`, `?`; confirm destructive.
6. `lint-panel` (T2 user request, estimated large, split at its start, S11+): diagnostics list; rubocop state; `:grep :make :cnext :copen`.
7. `git-push-pull` (T2 user request, estimated medium, S11+): `P` asks before a push, never force; `F` pulls.
8. `git-diff-blame` (T2 user request, estimated medium, S11+): `=` diffs the file; a blame line.
9. `language-any` (T2 user request, estimated medium, S11): `language.<name>.lsp` lines.
10. `vim-macros-marks` (T2 user request, estimated medium, S11).
11. `vim-case-increment` (T2 user request, estimated medium, S11).
12. `vim-line-commands` (T2 user request, estimated medium, S12).
13. `vim-folds` (T2 user request, estimated medium, S12).
14. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
15. `formatting` (T5 roadmap 14, estimated medium, S13).
16. `ux-pass-2` (T2 user now-request, estimated medium, S13).
17. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S14).
18. `release-build` (T5 roadmap 15, estimated medium, S14).
19. `sample-plugin` (T5 user-scheduled, estimated medium, S14).
20. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; `test/lint.rb:255`; `docs/spinel-notes.md:47`.
21. `dogfooding` (T2 user request, estimated medium, S15).
22. `ux-fixes-b` (T2 user now-request, estimated medium, split at its start, S15): ux-pass findings 1, 2, 4, 6, 7, 8, 9, 11.
23. `claude-bridge` (T2 user request, estimated large, split at its start, idea, the user to confirm, not before S15): carat as an IDE a Claude Code session connects to, as the official editor extensions and claudecode.nvim do: it sees the open file, selection, diagnostics; its edits open as a diff a key accepts or rejects, landing through Buffer's one edit path; the local connection token-guarded; the protocol checked against Claude Code's documentation at planning.
24. `claude-workflow` (T2 user request, estimated large, split at its start, idea, the user to confirm, after claude-bridge): a keyboard-only guided loop: ask, a plan buffer to edit and approve, step-by-step implementing, each diff accepted, rejected, or edited, tests in quickfix, a review pass, a commit buffer; `:Claude ask|plan|review|stop`, leader bindings in `config/default.caratrc`, a git-panel-like panel (y, n, e, d, r, ?), palette commands.
25. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
26. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
27. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
28. `finder-grep` (T5 user request, estimated medium, pushed back 6).
29. `definition-tab` (T5 user request, estimated medium, pushed back 6).
30. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
31. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
32. `filetype-rules` (T5 user request, estimated medium, pushed back 6).
33. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).
34. `syntax-forms` (T5 user request, estimated medium, pushed back 6).
35. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).
36. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).
37. `html-syntax` (T5 user request, estimated medium, pushed back 6).
38. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
39. `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`.
40. `insert-copy` (T4, estimated small, pushed back 12).
41. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`, `:22`.

## Guide

The user's guide, security first:

- S9 to S15: three features, two fixes each by the sprint tags; `gate-object-pin` first if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- A language's diagnostics come from its language server; carat adds no built-in checkers; refuse an item proposing one.
- Pipeline items: `review-demotion` and `scout-value` first (sprint-9 throughput).
- Dropped: carat drawing its own glyphs (`nerd` stays an option).

## Decisions

- Sprint 10 (T2): 1 feature, 4 backlog by the user, still 5; `git-signs-status-b`, `lsp-container` (T2) head the pool, S11.
