# Backlog: carat/use_cases/files/quit.rb

## Quit copies the close-other-windows loop

- Where: `carat/use_cases/files/quit.rb` line 82 (close_page) against `carat/use_cases/windows/close_other_windows.rb` line 27, at c1b3a12 (periodic quality). Queued in `buffer-list-tidy`.
- Why it matters: two copies of closing every window of a tab page but one.
- Fix outline: one BufferList method both call.
- Also: carat/use_cases/windows/close_other_windows.rb
- Category: editor
- Added: 2026-11-09

## Quit walks the leaves to count file windows

- Where: `beside_side_windows?` in `carat/use_cases/files/quit.rb` line 66, at 7711421. Periodic quality. Queue item `top-rows`.
- Why it matters: it repeats `TabPage#file_window_count`.
- Fix outline: call `file_window_count`.
- Category: editor
- Added: 2026-11-09

### Two definitions of a side window coexist after tab-close-c
- Location: carat/use_cases/files/quit.rb:87
- Why: TabPage#side_window? (a shown slot's window, the one place per the design) now sits beside Quit#beside_side_windows?, TabPage#editing_leaf, and file_window_count, which treat any scratch-buffer window as a side window, so :q counts a reading view or a pinned documentation split as a side window while buffer switches do not.
- Fix: route Quit#beside_side_windows? through TabPage#side_window?, or name the scratch-based notion apart (file window versus side window) in code and docs.
- Category: editor
- Added: 2026-11-17

### Quit walks the layout for a question BufferList answers (sprint-16 sweep quality)

- Location: carat/use_cases/files/quit.rb:87 (beside_side_windows?), BufferList#lone_file_window? at buffer_list.rb:475.
- Why: a private walk duplicates the predicate DeleteBuffer uses.
- Fix outline: use !state.buffer.scratch? && @buffers.lone_file_window?(state.tab) and delete the walk.
- Category: editor
- Added: 2026-11-18

### Duplication (sprint-20 sweep quality, quit.rb:87)

- Location: `carat/use_cases/files/quit.rb:87`
- Why: duplication: beside_side_windows? restates BufferList#lone_file_window? (carat/domain/buffer_list.rb:491) plus a scratch check, and lone_file_window? reads only the TabPage it is given
- Fix: move it to TabPage#lone_file_window? and use it from Quit (with !state.buffer.scratch?), DeleteBuffer, and BufferList#close_windows_of
- Also: carat/domain/buffer_list.rb
- Category: editor
- Added: 2026-11-19
