# Backlog: carat/use_cases/plugins/window_requests.rb

## WindowRequests#in_window keeps a dead local and an unobservable restore

- Where: `in_window` in `carat/use_cases/plugins/window_requests.rb` lines 293 and 304 at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: it assigns `state = @state` and never reads it (the block captures `open_file`'s own state), and it restores the float focus although its only caller, `open_file`, then calls `focus_at`, whose `TabPage#focus` leaves the float again, so the restore is never observable.
- Fix outline: delete the dead line, and drop `saved_float` and its `enter`, or document that `in_window` keeps the focus for callers that do not refocus. Queued in `float-placement` with the other `floating-windows` notes.
- Category: plugins
- Added: 2026-11-07

## move_float bypasses the float use cases

- Where: `WindowRequests#move_float` in `carat/use_cases/plugins/window_requests.rb` (line 247 at 803fe6e). Periodic quality advisory.
- Why it matters: `open_float` and `close_float` go through `OpenFloat` and `CloseFloat` as section 5.3 asks of request families, while `move_float` writes the tab page's `FloatLayer` directly and ignores the result of `move`.
- Fix outline: a `MoveFloat` use case beside the other two, or a class comment saying a move is a domain write needing none, with `FloatLayer#move` made void. Queued in `float-placement`.
- Category: plugins
- Added: 2026-11-07

## The side string is mapped by a nested ternary and dispatched in four places

- Where: `carat/use_cases/plugins/window_requests.rb` lines 319 to 321, and the side dispatch in `TabPage#slot`, `TabPage#slot_at`, `Options#slot_size`, and `ToggleSlot#name_of`, at edaf2c2. Quality advisories in `layout-slots`, raised twice.
- Why it matters: the nested ternary is harder to read than the `if`/`elsif` of `TabPage#slot`, and four copies of the side dispatch drift when a slot is added.
- Fix outline: map the side once with a `case` or a small lookup and keep the per-side dispatch in `TabPage`.
- Category: plugins
- Added: 2026-11-09

## The window requests comments are stale since the slots change

- Where: `open_file` in `carat/use_cases/plugins/window_requests.rb` line 145 and the class comment, lines 24 to 32, at 5e4c140. Periodic quality. Queue item `slots-tidy`.
- Why it matters: `unfix_size` at line 162 also drops a bottom panel's fixed height, and scratch buffers no longer open only in side windows.
- Fix outline: say the slot window loses its fixed size and rewrap the class comment.
- Category: plugins
- Added: 2026-11-09

## WindowRequests#float_frame takes a name it never reads (float-placement, quality advisory)

- Where: `carat/use_cases/plugins/window_requests.rb:260`.
- Why it matters: dead parameter: float_frame takes name and never reads it.
- Fix outline: drop it from WindowRequests#float_frame and its PluginLink call, or say in the comment that it keeps the request family's shape.
- Category: plugins
- Added: 2026-11-14

## A plugin's tab page switch skips TabList#visit (sprint-2 review)

- Where: `carat/use_cases/plugins/window_requests.rb:132` (the float branch of focus_window) and `focus_at` at line 281 (focus_window, open_file, open_in_split) assign the tab index directly. Sprint-2 review at 8b9bf6a.
- Why it matters: the last tab page is not updated, so `g<Tab>` goes to the wrong tab page after the finder or explorer focuses a window in another tab page, unlike Vim.
- Fix outline: switch through `TabList#visit`, with a row where a plugin focuses a window in another tab page and `g<Tab>` returns. Pool item `definitions-tidy`.
- Category: plugins
- Added: 2026-11-14

### Plugin host code repeats itself and breaks two record rules

- Location: carat/use_cases/plugins/window_requests.rb:95 with ui_requests.rb:82 (binding errors loop), window_requests.rb:179 (split save and restore beside in_window at :303), buffer_requests.rb:144 with window_requests.rb:344, :347 (cursor_on), plugin_events.rb:205 (detail uncopied), pending_event.rb:9 (Struct never mutated), plugin_registry.rb:175 (recomputes cause), ui_requests.rb:123 and 4 more files (`e` for an entry), carat/plugins/explorer/plugin.rb:194, :331, :404, :422 and :160 (cursor_to and toggle) (sprint-8 sweep, quality); queued in `plugin-host-tidy`.
- Why: duplicated helpers, a string crossing the plugin boundary uncopied, a Data value written as a Struct, and an unclear abbreviation.
- Fix: one record_bindings, splits through in_window, one cursor helper, `detail.dup`, a Data subclass, `= cause`, `entry`, and a private cursor_to with toggle calling focus.
- Also: carat/plugins/explorer/plugin.rb
- Category: plugins
- Added: 2026-11-16

### The E36 branch of open_file_window has no test

- Location: carat/use_cases/plugins/window_requests.rb:287
- Why: the branch that returns E36 for `close_scratch` on the editor's last window, replacing the old E444, is never exercised, so its message and the state it leaves are unproven (missing test).
- Fix: add a row closing a lone scratch window with no room for a split, or drop the branch if it cannot happen.
- Category: plugins
- Added: 2026-11-17

### open_file_window repeats SplitWindow with another minimum width (sprint-13 quality)
- Location: carat/use_cases/plugins/window_requests.rb:283, :291; carat/use_cases/windows/split_window.rb:36; plugin_registry.rb:360.
- Why: it repeats floats.leave, layout.split, E36, adopt, focus, load, passing a minimum width of 1 where SplitWindow passes gutter width + 1, while the registry handles the same last-plugin-window case with an in-place show and unfix_size: two ways to do one thing; file_at(1) restates first_file.
- Fix: one shared path for both cases, and first_file. Queue item `windows-buffers-walk`.
- Also: carat/use_cases/windows/split_window.rb
- Category: plugins
- Added: 2026-11-17

### close_scratch's E36 refusal has no test (sprint-13 quality)
- Location: carat/use_cases/plugins/window_requests.rb:287.
- Why: closing a lone scratch window with no room for the file window answers E36 untested, unlike the other close_scratch scenarios (test/editor_plugins.rb, test/editor_explorer.rb).
- Fix: a row closing a lone tree in a window too small to split, expecting E36. Queue item `windows-buffers-walk`.
- Also: test/editor_plugins.rb, test/editor_explorer.rb
- Category: plugins
- Added: 2026-11-17

### The host's open_as_tab fallback with no file window is reached by no shipped caller
- Location: carat/use_cases/plugins/window_requests.rb:214, docs/plugins.md:79
- Why: every shipped plugin now checks editing_window before open_as_tab, so the host's no-file-window fallback to a tab page is dead for shipped callers, and docs/plugins.md asks each plugin to repeat the check
- Fix: at the next plugin API minor step make open_as_tab with no file window open in the current window as open_file does, and drop the finder's own check
- Also: docs/plugins.md
- Category: plugins
- Added: 2026-11-18

### Each float request resolves the same float three times (sprint-23 review quality)
- Location: carat/use_cases/plugins/window_requests.rb:370 (`unlisted_float_tab`), :281 (`set_float_lines`), :308 (`style_float`).
- Why: unlisted_float_tab resolves the float through float_in after own_float_tab already did, and both requests call float_in(index, id) again, three lookups per request; picker-styles-b's quality advisory (its run state note 2) raised the same copy.
- Fix: one private helper returning the plugin's unlisted float or nil, used by both requests in place of unlisted_float_tab plus float_in, with the existing float tests unchanged.
- Category: plugins
- Added: 2026-11-20

### Two plugin requests copy the keymap error loop (sprint-24 sweep quality)

- Location: `carat/use_cases/plugins/window_requests.rb:101`, `carat/use_cases/plugins/ui_requests.rb:83`
- Why: open_scratch and live_prompt repeat the loop recording each binding error.
- Fix: one `PluginRegistry#record_bindings(name, keymap)`.
- Also: carat/use_cases/plugins/ui_requests.rb
- Category: plugins
- Added: 2026-11-21

### own_float_tab repeats float_in's lookup (floats.at(floats.index_of(window_or_current(id)))) at carat/use_cases/plugins/window_requests.rb:379 (sprint-26 sweep quality, note 53)

- Location: carat/use_cases/plugins/window_requests.rb:379
- Why: own_float_tab repeats float_in's lookup (floats.at(floats.index_of(window_or_current(id))))
- Fix: return float_in(index, id).window.buffer.owner == name ? index : -1
- Category: plugins
- Added: 2026-11-22

### own_float_tab repeats float_in's lookup at carat/use_cases/plugins/window_requests.rb:378 (sprint-28 sweep quality, note 37)

- Location: carat/use_cases/plugins/window_requests.rb:378, :396
- Why: two copies of one lookup.
- Fix: return float_in(index, id).window.buffer.owner == name ? index : -1.
- Category: plugins
- Added: 2026-11-22

### duplication: own_float_tab repeats float_in's lookup (floats.at(floats.index_of(target))) and window_or_current, and float_in at carat/use_cases/plugins/window_requests.rb:398 (sprint-32 sweep quality, note 68)
- Location: carat/use_cases/plugins/window_requests.rb:398
- Why: duplication: own_float_tab repeats float_in's lookup (floats.at(floats.index_of(target))) and window_or_current, and float_in then repeats it for every caller after own_float_tab or unlisted_float_tab
- Fix: have own_float_tab call float_in(index, id) once the tab index is known
- Category: quality

### in_window, and open_in_split's hand-rolled copy at 204-212, put the tab at carat/use_cases/plugins/window_requests.rb:500 (sprint-32 sweep quality, note 69)
- Location: carat/use_cases/plugins/window_requests.rb:500
- Why: in_window, and open_in_split's hand-rolled copy at 204-212, put the tab page, current window, and float focus back only on a normal return, with no ensure, so an open that raises inside a guarded plugin call leaves the editor focused on the borrowed window
- Fix: restore in an ensure and have open_in_split use in_window
- Category: quality
