# Backlog: carat/adapters/tab_bar.rb

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

### The tab bar re-scans the list for a shared name on every width
- Location: `carat/adapters/tab_bar.rb`, `shares_name?` called by `tab_width` and `paint_tab`.
- Why: each tab width compares its name with every other file tab, and the overflow loops call `span_width` repeatedly, so a row with many listed files costs about the cube of the tab count in byte compares per frame (most end on the length test); no allocation, but it grows with the buffer list.
- Fix: compute once per paint a count of tabs per last segment, or cache a shared flag on `BufferList` flushed on open, close, and rename, and read it in `tab_width`.
- Category: editor
- Added: 2026-11-24

### and carat/adapters/tab_bar.rb:14 comment lines left unwrapped by the last edits at carat/plugin_api.rb:422 (sprint-32 sweep quality, note 39)
- Location: carat/plugin_api.rb:422
- Why: and carat/adapters/tab_bar.rb:14 comment lines left unwrapped by the last edits amid 72-column text
- Fix: rewrap them
- Merged: sprint-32 sweep note 64, the same finding
- Category: quality

### shares_name? scans every buffer and runs from tab_width inside span_width's at carat/adapters/tab_bar.rb:213 (sprint-32 sweep quality, note 46)
- Location: carat/adapters/tab_bar.rb:213
- Why: shares_name? scans every buffer and runs from tab_width inside span_width's loops and again from paint_tab, so an overflowing row costs quadratic to cubic byte compares per frame
- Fix: compute the shared-name flags once per paint
- Category: quality
