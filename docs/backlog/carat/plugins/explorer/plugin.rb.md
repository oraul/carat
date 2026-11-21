# Backlog: carat/plugins/explorer/plugin.rb

## The file tree's cursor drifts when follow expands directories above it

- Where: `Carat::Plugins::Explorer::Plugin#follow` in `carat/plugins/explorer/plugin.rb`, and the plugin API, whose `move_cursor` request moves only the current window's cursor.
- Why it matters: while the tree is open but not current, opening a file in another directory expands that directory and inserts lines above the tree's cursor, which then sits on a different entry than before; Neovim's tree plugins move the tree's cursor to the followed file. `:ExplorerFind` and opening the tree put the cursor right, so only the unfocused case drifts.
- Fix outline: add a request that moves the cursor of a window by number (or of the plugin's scratch window by title) without focusing it, bump the API minor version, and have `follow` put the tree's cursor on the marked row after it refreshes.
- Category: plugins
- Added: 2026-10-29

## The explorer's tokenize walks bytes to find an icon column it already knows

- Where: `tokenize` in `carat/plugins/explorer/plugin.rb` (line 143 at `theme-tokens`), which re-decodes the marker's UTF-8 length with a nested ternary and counts spaces to find the icon's column.
- Why it matters: the plugin already knows the column when it builds the line (1 + 2 * depth), so the byte walk is cleverness the task did not need and a second place to change when the line's layout does.
- Fix outline: record the icon column beside the group in `tree_lines` (or take it from `Tree`'s depth) and drop the byte walk.
- Category: plugins
- Added: 2026-11-05

## The explorer's token table is keyed by whole tree lines

- Where: `tokenize` and the `@line_groups` table in `carat/plugins/explorer/plugin.rb` (lines 139 and 467 at `theme-tokens`), rebuilt by `tree_lines` on every refresh. Periodic quality at 4c65f4e.
- Why it matters: a line's tokens depend on plugin state instead of the line, though every icon the tree draws has its own glyph in each icon set, so the table is state the plugin need not keep.
- Fix outline: build a glyph-to-group table once in `activate` from `host.icon` and `FileIcons::GROUPS`, look up the glyph at the icon column in `tokenize`, and drop `@line_groups` and `tree_lines`, together with the byte-walk entry above it. Queued in `carat-palette`.
- Category: plugins
- Added: 2026-11-05

## The explorer's Tree takes a positional boolean the keyword rule forbids

- Where: `Tree.new` in `carat/plugins/explorer/plugin.rb` (line 484 at `explorer-folder-toggle`), passing the hidden-files flag positionally, while `test/lint.rb` (line 674) exempts `carat/plugins/` and `carat/plugin_api.rb` from the keyword-constructor check that `CLAUDE.md` states without exception. Periodic quality advisory at 3a99ddd.
- Why it matters: a bare `true` or `false` at the call site reads as nothing, and the rule and its check disagree, so a reader cannot tell whether plugins must follow it.
- Fix outline: give `Tree` keyword arguments (root, the hidden-files flag, the ignore list), and state the plugin exemption, or its absence, in `CLAUDE.md` beside the lint rule.
- Also: test/lint.rb, carat/plugin_api.rb, CLAUDE.md
- Category: plugins
- Added: 2026-11-05

## The explorer queries the current window with focus_window

- Where: `carat/plugins/explorer/plugin.rb:202` (periodic quality at 5722559).
- Why it matters: `host.focus_window(0)` has effects (sets the tab page, re-enters a focused float) but is used as a query.
- Fix outline: a read-only host request for the current window (Host method, PluginLink override, WindowRequests method, minor version bump) or the window in `PluginApi::Command`, called here.
- Category: plugins
- Added: 2026-11-07

## The explorer's help restates its keymap

- Where: `HELP` in `carat/plugins/explorer/plugin.rb` line 16 against its keymap at line 541, at 38628bb (periodic quality). In the backlog items of the queue.
- Why it matters: a changed key leaves the `?` message wrong.
- Fix outline: build the help from the keymap lines once, or let `?` show the key hints.
- Category: plugins
- Added: 2026-11-09

## The explorer opens left on any side but right

- Where: `carat/plugins/explorer/plugin.rb` line 516 (`side`), and `carat/use_cases/plugins/window_requests.rb` line 70 (`open_scratch`'s `width`, rows for the bottom panel since 2.4, and a failure text restating `PluginApi::SIDES`), at 31919d9. Periodic quality. Queue item `slots-tidy`.
- Why it matters: `plugin.explorer.side bottom` or a typo silently opens the tree on the left with no problem reported; a parameter named for columns carries rows.
- Fix outline: pass `bottom` through and report an unknown side, with a row; rename the parameter `size` and build the message from the sides list.
- Also: carat/use_cases/plugins/window_requests.rb
- Category: plugins
- Added: 2026-11-09

## The explorer keeps a stale followed path after a directory rename

- Where: `finish_rename` in `carat/plugins/explorer/plugin.rb` line 420, against `Tree#moved` in `tree.rb` line 107; the duplicate `tree.mark(@followed)` in `show_tree` line 186, at 5e4c140. Periodic quality. Queue item 38 (explorer).
- Why it matters: renaming the open file's directory leaves the old, missing path marked and revealed until a focus event; the mark has two owners.
- Fix outline: apply the prefix rule to `@followed` or set it from `tree.marked`, drop the duplicate mark, with an `editor_explorer` row.
- Category: plugins
- Added: 2026-11-09

## The explorer spells its keys twice

- Where: `carat/plugins/explorer/plugin.rb:16` (`HELP`) against `:541` (its keymap).
- Why it matters: a changed key drifts from the help; the tree keymap takes no configuration line, unlike manifest bindings.
- Fix outline: build the help from the keymap lines and record in `docs/plugins.md` whether a scratch keymap takes configuration. Backlog batch: editing and keymap copies.
- Also: docs/plugins.md
- Category: plugins
- Added: 2026-11-10

### The explorer's help is one message line cut at the terminal's width

- Location: `carat/plugins/explorer/plugin.rb:16` and `:249`.
- Why: `?` prints every key on the message row and loses the end at 80 columns (`... d delet`), so `R`, `H`, `-`, `C`, and `q` are never shown (ux-pass review finding 4). Reproduction: start in an empty folder, `<Space>e`, `?`, `openspec/changes/archive/*-ux-pass/screens/empty-explorer-help.txt`.
- Fix: show the help as a bordered float like the key-hint menu, one key per row, closed by `<Esc>`, `q`, or `?`.
- Category: plugins
- Added: 2026-11-15

### The explorer keeps a deleted directory's expansions and marks (sprint-24 sweep quality)

- Location: `carat/plugins/explorer/plugin.rb:444`
- Why: finish_delete collapses only the deleted path, so a directory later made there reopens with its old subdirectories expanded.
- Fix: a `Tree#forget(path)` dropping the path, every key under it, and its marks, with a test in `test/plugins_explorer.rb`.
- Also: test/plugins_explorer.rb
- Category: plugins
- Added: 2026-11-21
