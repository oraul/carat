# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog.md`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 32.0 held.

## Sprint 9

## Pool

1. `markdown-reading-b` (T2 user now-request, feature, estimated medium, S10): tables aligned in box borders (ascii under option.icons ascii), left, center, right markers honored, cells wrapped in a narrow window; paragraphs and quotes flowed to the measure (6c7d37b at 60 columns: raw pipes, the separator row, ragged lines). Accepted when snapshots show a three-column aligned table at 100 and 60 columns, a two-line paragraph and quote flowed as one, no box cell under ascii, allocations held.

2. `git-signs-status-b` (T2 user request, part b, estimated medium, S10): added, changed, deleted line signs.

3. `lsp-container` (T2 user request, feature, estimated small, S10): a user-file line `language.<name>.lsp.root ROOT COMMAND...` runs that command as written, no shell, as the server under ROOT, elsewhere `language.<name>.lsp`; no path translation (same-path mount: docker compose run -v P:P -w P); carat never starts, stops, or restarts a container, ending only its server process; a project's `.caratrc` names no program. Accepted when a test shows the root's command under ROOT, the default elsewhere, the project file's line refused, quit and :LspRestart ending only the server.

4. `ux-fixes-a` (T2 user now-request, estimated medium, S11 by the user): ux-pass findings 3, 5, 10: the status-bar hole, the finder dropping its query, the palette's internal names.

5. `markdown-reading-c` (T2 user request, feature, estimated medium, after markdown-reading-b): heading levels drawn apart, code blocks framed with their language label, the rule at full measure, a gap between adjacent lists.

6. `git-panel` plugin (T2 user request, estimated large, pushed back 1, split at its start, S11+): Unstaged, Staged, Recent; `s`, `u`, `c`, `?` help, a confirmation before anything destructive.

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

24. `markdown-preview` plugin (T2 user now-request, estimated medium, pushed back 4).

25. `mermaid-flowchart` (T2 user now-request, estimated large, pushed back 4, split at its start).

26. `mermaid-sequence` (T2 user now-request, estimated medium, pushed back 4).

27. `finder-grep` (T5 user request, estimated medium, pushed back 6).

28. `definition-tab` (T5 user request, estimated medium, pushed back 6).

29. `finder-pickers` (T5 user request, estimated medium, pushed back 6).

30. `csv-viewer` plugin (T5 user-scheduled, estimated large, pushed back 10).

31. `filetype-rules` (T5 user request, estimated medium, pushed back 6).

32. `syntax-definitions` (T5 user request, estimated medium, pushed back 6).

33. `syntax-forms` (T5 user request, estimated medium, pushed back 6).

34. `syntax-embedded` (T5 user request, estimated medium, pushed back 6).

35. `javascript-syntax` (T5 user request, estimated medium, pushed back 6).

36. `html-syntax` (T5 user request, estimated medium, pushed back 6).

37. `bidi-controls` (T3 security Lows, estimated small, pushed back 11).

38. `project-config-guards` (T3, estimated medium, pushed back 23): `config.rb:221`.

39. `insert-copy` (T4, estimated small, pushed back 12).

40. `bench-scenarios` (T4 tests, estimated small, pushed back 1): `bench/run.sh:69`, `:22`.

## Guide

The user's guide (2026-11-15, 2026-11-16), security first:

- S9 to S15: three features, two fixes each by the sprint tags; `gate-object-pin` first if rated T0; S15 holds `dogfooding` and two features S7 to S14 reveal.

- A language's diagnostics come from its language server; carat adds no built-in checkers; refuse an item proposing one.

- Sprint-9 throughput analysis: `review-demotion` and `scout-value` weighed first among pipeline items.

- Dropped: carat drawing its own glyphs (`nerd` stays an option).
