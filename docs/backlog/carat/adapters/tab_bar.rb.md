# Backlog: carat/adapters/tab_bar.rb

## The [No Name] text is defined in both bars

- Where: `NO_NAME` in `carat/adapters/tab_bar.rb` (line 23 at `bars`) and again in `carat/adapters/status_bar.rb` (line 46); at 7711421 also `carat/adapters/winbar.rb` line 17, `carat/use_cases/buffers/list_buffers.rb` line 20, and `carat/domain/messages.rb` line 16 (periodic quality note 33). Quality advisory of `bars`, raised twice.
- Why it matters: one user-visible text has two owners that can drift apart.
- Fix outline: keep one constant, for example beside `Buffer#display_name`, and reference it from both bars.
- Also: carat/adapters/status_bar.rb, carat/adapters/winbar.rb, carat/use_cases/buffers/list_buffers.rb, carat/domain/messages.rb
- Category: editor
- Added: 2026-11-05

## TabBar#icon_group scans every group name on each frame

- Where: `icon_group` in `carat/adapters/tab_bar.rb` (line 136 at `bars`) calls `Highlight.token_id` over every syntax and icon name each time it draws the selected tab, while the `bars` design says the group is resolved once per name. Quality advisory of `bars`.
- Why it matters: a linear scan per frame for a value that changes only with the buffer's icon, and the design text no longer matches the code.
- Fix outline: resolve the group once per icon name (a small Hash, or an id kept beside `Buffer#icon`), or correct the design text, with the tab bar test rows unchanged.
- Category: editor
- Added: 2026-11-05

### Quality: the tab bar's modified-mark fallback cannot trigger, carat/adapters/tab_bar.rb:137

- Why: speculative generality; the `mark(set)` fallback to the ASCII mark cannot trigger, since every shipped set's modified glyph is one cell and the sets are constants, yet it measures the glyph for each modified tab on every frame.
- Fix: drop the fallback and add a test that each set's modified glyph measures one cell, or test the fallback through a wide glyph.
- Category: editor
- Added: 2026-11-14

### carat/adapters/tab_bar.rb:22: NO_NAME "[No Name]" is also defined in carat/adapters/winbar.rb:18, carat/adapters/status_bar.rb:47 (sprint-22 sweep quality)

- Location: `carat/adapters/tab_bar.rb:22`
- Why: NO_NAME "[No Name]" is also defined in carat/adapters/winbar.rb:18, carat/adapters/status_bar.rb:47, carat/use_cases/buffers/list_buffers.rb:22, and written out in carat/domain/messages.rb:22
- Fix: one Domain::Messages::NO_NAME constant that the other four use
- Also: carat/adapters/winbar.rb, carat/adapters/status_bar.rb, carat/use_cases/buffers/list_buffers.rb, carat/domain/messages.rb
- Category: editor
- Added: 2026-11-20

### Comment lines left unwrapped in three files (sprint-24 sweep quality)

- Location: `carat/adapters/tab_bar.rb:19`, `carat/use_cases/plugins/plugin_router.rb:60`, `carat/use_cases/plugins/file_requests.rb:28`
- Why: unwrapped lines amid wrapped prose.
- Fix: rewrap to the surrounding width.
- Also: carat/use_cases/plugins/plugin_router.rb, carat/use_cases/plugins/file_requests.rb
- Category: editor
- Added: 2026-11-21

### The head reuses three existing groups
- Location: `carat/adapters/tab_bar.rb`, `paint_head` (Normal, NonText, MsgDim lifted onto the sidebar layer)
- Why: the groups are named for other uses, so a theme author cannot restyle the head alone; the council's `one-accent` item adds a bold no-fill group the head could take.
- Fix: when `one-accent` adds its groups, give the head its own (project, dot, branch) and drop the reuse; the tests name the groups by id, so they change with it.
- Category: editor
- Added: 2026-11-23

### The project name is the base directory of the last opened file
- Location: `carat/adapters/tab_bar.rb`, `paint_head` (reads `BufferList#base`)
- Why: `base` is set at startup and by `OpenFile`, not by `:cd`, so after a directory change the head can name the old project until a file is opened; the explorer's root row follows the working directory.
- Fix: have the working-directory change set `BufferList#base`, or give the presenter the working directory through the state, with a test that `:cd` renames the head.
- Category: editor
- Added: 2026-11-23

### Neighbouring tabs are three cells apart, not two
- Location: `carat/adapters/tab_bar.rb`, `paint_tab` (`FRAME_CELLS`)
- Why: removing the separator leaves the trailing space and the next tab's two leading spaces; the council's spec is two blank cells, with the icon gone and the padding space, name, space, mark, space.
- Fix: in `one-accent`, which removes the icon, set the padding to the spec, `FRAME_CELLS` to 3, and update the expected rows of `adapters_tab_bar`, `editor_tabs`, and `editor_tab_flows`.
- Category: editor
- Added: 2026-11-23

### A narrow sidebar cuts the head silently
- Location: `carat/adapters/tab_bar.rb`, `paint_head`
- Why: below about 14 columns the project is cut at the sidebar's edge with no ellipsis, and the branch is dropped first; the council defers the rules for narrow widths.
- Fix: in the narrow-widths item, cut the project with an ellipsis and drop the branch below a width, with a table-driven test of the widths.
- Category: editor
- Added: 2026-11-23

### The tab mark under a focused float
- Location: `carat/adapters/tab_bar.rb`, `selected_buffer`
- Why: a focused float, such as the finder, is `state.window`, so its scratch buffer leaves no tab selected, as the explorer's did before this change; the brief asks for sidebars only.
- Fix: while a float has focus, select the tab of the layout window (`TabPage#layout_window`) in `selected_buffer`, with a test that focuses a float over a file window.
- Category: editor
- Added: 2026-11-23

### TabBar#paint_head re-derives the last path segment at carat/adapters/tab_bar.rb:132 (sprint-31 review quality)
- Location: carat/adapters/tab_bar.rb:132, beside carat/domain/buffer.rb:276 (name_start) and PluginApi::Paths.basename
- Why: a third copy of the slash scan, each with its own edge cases (the root, a trailing slash), so they can disagree on what the project is called.
- Fix: one shared index helper in the domain that the head, Buffer#name_start, and the tabs read.
- Also: carat/domain/buffer.rb
- Category: editor
- Added: 2026-11-23
