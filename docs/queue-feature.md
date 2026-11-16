# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 10

## Pool

1. `markdown-reading-c` (T2 user now-request, feature, estimated small, S11, split from markdown-reading-b by the user's rule): at 60 columns the reading view (`carat/domain/markdown_text.rb`) shows paragraphs and block quotes as ragged source lines. Outline: flow each to the window's measure. Fold: callers pass `carat/use_cases/docs/format_docs.rb:33` bare bool literals (sprint-9 note 12). Accepted when snapshots show a two-line paragraph and a two-line quote each flowed as one at 60 columns, allocations held. Backlog: none.
2. `git-signs-status-b` (T2 user request, part b, feature, estimated medium, S11 by the user): no sign shows a line added, changed, or deleted. Part a (#148) runs two captures on the editor thread per buffer_open, buffer_save, window_focus (`carat/plugins/git_signs/plugin.rb:43`, `:60`), up to 4 s (sprint-9 Low (5)), and its `rev-list` (`plugin.rb:23`) can lazy-fetch from an untrusted `.git`'s promisor remote, running its command (Medium (6)); a diff capture adds a third. Outline: the three signs, refreshes bounded. Accepted when a canned git shows each sign kind on its lines, a focus change with HEAD and the file unchanged runs no git, a timed-out capture stalls no later event, a case's partial clone with a command promisor runs no command, allocations held. Backlog: "### git_signs rev-list can lazy-fetch from a promisor remote in an untrusted .git (security Medium, confidence 6)", "### git_signs runs git synchronously on the editor thread".
3. `lsp-container` (T2 user request, feature, estimated medium, pushed back 1, S11 by the user): only `language.<name>.lsp` (`config/default.caratrc:749`) names a server. Outline: a user-file line `language.<name>.lsp.root ROOT COMMAND...` runs that command as written, no shell, as the server under ROOT, elsewhere `language.<name>.lsp`; no path translation; carat never manages a container, ending only its server process; a project's `.caratrc` names no program. Accepted when a test shows the root's command under ROOT, the default elsewhere, the project file's line refused, quit and :LspRestart ending only the server. Backlog: none.
4. `ux-fixes-a` (T2 user now-request, estimated medium, S11 by the user): ux-pass findings 3, 5, 10: the status-bar hole, the finder dropping its query, the palette's internal names.
5. `markdown-reading-d` (T2 user request, feature, estimated medium, after markdown-reading-c, renamed from markdown-reading-c): headings, framed code blocks, rules, list gaps.
6. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start, S11+): Unstaged, Staged, Recent; `s`, `u`, `c`, `?`; confirm destructive.
7. `lint-panel` (T2 user request, estimated large, split at its start, S11+): diagnostics list; rubocop state; `:grep :make :cnext :copen`.
8. `git-push-pull` (T2 user request, estimated medium, S11+): `P` asks before a push, never force; `F` pulls.
9. `git-diff-blame` (T2 user request, estimated medium, S11+): `=` diffs the file; a blame line.
10. `language-any` (T2 user request, estimated medium, S11): `language.<name>.lsp` lines.
11. `vim-macros-marks` (T2 user request, estimated medium, S11).
12. `vim-case-increment` (T2 user request, estimated medium, S11).
13. `vim-line-commands` (T2 user request, estimated medium, S12).
14. `vim-folds` (T2 user request, estimated medium, S12).
15. `plugin-protocol-a` (T5 user-scheduled, estimated medium, S13).
16. `formatting` (T5 roadmap 14, estimated medium, S13).
17. `ux-pass-2` (T2 user now-request, estimated medium, S13).
18. `plugin-protocol-b` (T5 user-scheduled, estimated medium, S14).
19. `release-build` (T5 roadmap 15, estimated medium, S14).
20. `sample-plugin` (T5 user-scheduled, estimated medium, S14).
21. `spinel-workarounds` (T2 user request, estimated medium, pushed back 5, S14): `json.rb:72`; `test/lint.rb:255`; `docs/spinel-notes.md:47`.
22. `dogfooding` (T2 user request, estimated medium, S15).
23. `ux-fixes-b` (T2 user now-request, estimated medium, split at its start, S15): ux-pass findings 1, 2, 4, 6, 7, 8, 9, 11.
24. `claude-bridge` (T2 user request, estimated large, split at its start, idea, the user to confirm, not before S15): carat as an IDE a Claude Code session connects to, as the official editor extensions and claudecode.nvim do: it sees the open file, selection, diagnostics; its edits open as a diff a key accepts or rejects, landing through Buffer's one edit path; the local connection token-guarded; the protocol checked against Claude Code's documentation at planning.
25. `claude-workflow` (T2 user request, estimated large, split at its start, idea, the user to confirm, after claude-bridge): a keyboard-only guided loop: ask, a plan buffer to edit and approve, step-by-step implementing, each diff accepted, rejected, or edited, tests in quickfix, a review pass, a commit buffer; `:Claude ask|plan|review|stop`, leader bindings in `config/default.caratrc`, a git-panel-like panel (y, n, e, d, r, ?), palette commands.
26. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).
27. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).
28. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).
29. `finder-grep` (T5 user request, estimated medium, pushed back 6).
30. `definition-tab` (T5 user request, estimated medium, pushed back 6).
31. `finder-pickers` (T5 user request, estimated medium, pushed back 6).
32. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).
33. `filetype-rules` (T5 user request, estimated medium, pushed back 6).
34. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).
35. `syntax-forms` (T5 user request, estimated medium, pushed back 6).
36. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).
37. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).
38. `html-syntax` (T5 user request, estimated medium, pushed back 6).
39. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).
40. `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`.
41. `insert-copy` (T4, estimated small, pushed back 12).
42. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`, `:22`.

## Guide

The user's guide, security first:

- S9 to S15: three features, two fixes each by the sprint tags; `gate-object-pin` first if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.
- A language's diagnostics come from its language server; carat adds no built-in checkers; refuse an item proposing one.
- Pipeline items: `review-demotion` and `scout-value` first (sprint-9 throughput).
- Dropped: carat drawing its own glyphs (`nerd` stays an option).

## Decisions

- Delivered `markdown-reading-b` (T2) removed: Sprint 10 drained, 0 of 3, its fifth change, waiting for /sprint.
- `markdown-reading-c` (T2, small) heads the pool, S11, by the user's split; the old `markdown-reading-c` renamed `markdown-reading-d`, one name per item, order unchanged.
- Estimate medium: markdown-reading-a 1,035,751 tokens and 74 min, git-signs-status-a 1,124,717 and 104 min, 3 parts.
