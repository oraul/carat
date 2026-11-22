# Queue: features

Ordered by `docs/goals.md`; folded findings are in `docs/backlog/`. Every feature is also accepted with a docs row, a table-driven test per command, key, and option, and `lh` 26.0, `j` 27.0, `insert` 26.0 held.

## Sprint 29

1. `prompt-in-float` (T2 user request, estimated medium, Facet wave 4): Where: `carat/plugin_api.rb:885` (`prompt`), `:899` (`live_prompt`); `carat/adapters/frame_presenter.rb:107` (`PALETTE_PROMPT`); `carat/use_cases/discovery/follow_palette.rb:36`; `carat/plugins/finder/plugin.rb:38`. Why: the decided design types the query inside the modal float; the finder's prompt is `> ` with a counted title, the palette's `>` with none. Fix outline: the query row inside the float's frame for finder, palette, and pick lists, one prompt and title form; a plugin API minor if a request changes. Accepted when snapshots show the query and cursor inside the frame for finder and palette with matching prompt and title, PICKER_BUDGETS held. Backlog: "### The palette and the finder frame their prompt and title differently".

## Pool

1. `recent-files-persist` (T2, estimated small, pushed back 1): "### The recent files are kept for one run only"; `ui-groups-b` (T2, estimated medium): ui-groups' 4 headings (folder segment, StatusLine, ModeMsg, NO_COLOR bytes); `finder-word` (T2, estimated small): "### Space f w takes no word to the right of a blank cursor", "### word_at counts every non-ASCII character as a word character".
2. Facet waves 4 and 5 (T2 user request, estimated medium each): `dim-backdrop`, `float-polish` ("### The float key's layout is read in two classes at carat/adapters/frame_presenter.rb"), `separator-styles`, `one-accent`, `glyph-audit`; `plugin-ui-tokens` (a disputed Low (3)), `finder-refined`, `key-hints-dock`, `explorer-rows`; `start-gem`, `diagnostic-text`, `explorer-git`.
3. `finder-preview-gutter` (T2, estimated small, pushed back 2); `grep-finish`, `explorer-filter`, `finder-ranking`, `finder-layout`, `explorer-file-ops` (estimated medium each, pushed back 2); `search-count` (estimated medium, pushed back 6).
4. `background-theme` (T2 user request, estimated medium, pushed back 3, reason: Facet waves first, critical d carat/drivers/ansi_terminal.rb): 3 OSC 11 entries; the session-long OSC 11 wait (`ansi_terminal.rb:79`, sprint-28 sweep note 32).
5. `finder-path-safe` (T2 user request, security Lows (5), (3), estimated medium, pushed back 3, reason: its overlap waits for plugin-host-lows, critical a carat/plugin_api.rb): its 4 headings at 24e3738 less those plugin-host-lows lists.
6. `vim-folds-d` (T2, estimated medium, pushed back 2): 2 fold label headings; `markdown-reading-e` (T2, estimated medium, pushed back 6, reason: no location).
7. Async (T2 user request, estimated medium each, pushed back 2): `background-spike`, `idle-scheduler`, `plugin-tasks`, `task-programs`, `git-signs-tasks`, `finder-streaming`, `program-jobs`; debugger: `socket-probe`, `debug-keys` (estimated small), `debug-breakpoints`, `debug-channel`, `debug-session` (estimated large), `debug-stepping`, `debug-panel`, `debug-console`, `debug-more`.
8. `tree-spike`, `mermaid-spike`, `markdown-preview`, `mermaid-flowchart`, `mermaid-sequence` (T2, estimated medium each, pushed back 5, reason: after the UI track); `git-panel`, `lint-panel` (T2, estimated large); `claude-bridge`, `claude-workflow` (T2 ideas, estimated large).
9. Containers (T2 user request, estimated medium each, after the Facet waves and finder work): `dockerfile-support` (estimated small), `containers-panel` (`<leader>C`), `containers-logs` (after plugin-tasks), the rest as the notes of 2026-11-21 slice them.
10. `vim-increment` (T2, estimated small); `git-push-pull`, `git-diff-blame`, `language-any`, `vim-macros-marks`, `spinel-workarounds` (T2, estimated medium each).
11. `theme-tuning`, `semantic-highlight` (T5, estimated medium, estimated large); `plugin-protocol-a`, `formatting`, `plugin-protocol-b`, `release-build`, `sample-plugin`, `dogfooding`, `ux-fixes-b` (T5, estimated medium each).
12. `definition-tab`, `finder-pickers`, `filetype-rules`, `syntax-definitions`, `syntax-forms`, `syntax-embedded`, `javascript-syntax`, `html-syntax` (T5, estimated medium each, pushed back 7, reason: after the UI track); `csv-viewer` (T5, estimated large, pushed back 11).
13. `bidi-controls` (T3 Lows, estimated small, pushed back 12, reason: UI first): "### File text paints Unicode format characters raw (sprint-22 sweep security Low (6))"; `insert-copy` (T4, estimated small).

## Decisions

- Security first (T0): none; sprint-28 sweep High 0, Medium 1 at confidence 6, below 8; no `review.periodic-*` in the pending runs finder-rows, merge-path-lows, and review-in-openspec.
- `window-surfaces` delivered (T2 user request, Facet wave 3), estimated medium, not critical (its paths in no rule a to d): medium feature rows hidden-option 1,099,813 in 68 min, ui-groups 980,589 in 82, picker-speed 896,376 in 72, under 1.2M; the last two (finder-rows 1,213,986 large, finder-switch 918,545 medium) within budget, no size-up; not split: removing the glyph is accepted only with the darker sidebar (an edge stays visible) and the BORDER tone is one theme row.
- Sprint 29 (T2): `prompt-in-float` is the sprint's third and last feature.
- Notes (T1): finder-rows retro 3 (allocs.grep 774.4 to 786.1 found at the bench, rework 1) and 4 (base built twice, bench 110,265 of 459,208 output), merge-path-lows retro 2 (squash trailer, 1 of 25 commits) and 3 (check start with every stage passed, first.check 20 of 20): backlog-lane pipeline notes, left for that lane's planner (this brief touches no backlog-lane file).
