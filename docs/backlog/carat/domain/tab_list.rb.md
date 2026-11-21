# Backlog: carat/domain/tab_list.rb

## Five methods walk every window of every tab page

- Where: `shown?` (line 128 at 68eb750), `windows_showing` (line 145), `focus_buffer` (line 164), and the private `modified_in_page` (line 229) in `carat/domain/tab_list.rb`, and `BufferList#close_windows_of` in `carat/domain/buffer_list.rb` (line 308). Periodic quality advisory at 68eb750.
- Why it matters: a change to how windows are enumerated has to land five times.
- Fix outline: answer each question through one walk, for example `shown?` from `windows_showing`, with the `test/` rows unchanged. Queued as `buffer-list-structure` in `docs/queue.md`.
- Also: carat/domain/buffer_list.rb
- Category: editor
- Added: 2026-11-05

## A buffer shown only in a float counts as hidden

- Where: `shown?`, `windows_showing`, and `modified_in_windows` in `carat/domain/tab_list.rb` line 140 at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: they walk only the layout's windows, so after `:e` in a float a file buffer shown only there counts as hidden, which changes what `:q`, `:bd`, and the modified checks answer.
- Fix outline: include each page's float windows in the three walks, or refuse `:e` and `:b` in a float, with a test row either way.
- Category: editor
- Added: 2026-11-07

## A hidden slot's window keeps its cursor past a shrunk buffer

- Where: `clamp_cursors` in `carat/domain/tab_list.rb` line 225 at 847851d; reached by `set_scratch_lines` and the explorer's follow while its sidebar is hidden, shown again by `ToggleSlot` or `OpenSideWindow`. Periodic quality at 847851d (the review's one blocking finding, as read by the planner). Queue item `slots-tidy`.
- Why it matters: the window shows again with its cursor and top past the buffer's end, against the invariant area 8's Flow promises.
- Fix outline: clamp the windows kept by hidden slots too, with an `editor_slots` row shrinking a hidden explorer and toggling it back.
- Category: editor
- Added: 2026-11-09

## tab-keys quality advisory at carat/domain/tab_list.rb:213

- Why: test gap: focus_buffer now records a visit (the :q and :qa refusal moving to another tab page), but no test shows g<Tab> going back after it.
- Fix: add an editor_tabs row such as :tabe b.txt<CR>x<C-PageDown>:qa<CR>g<Tab> checking the tab page returned to.
- Category: editor
- Added: 2026-11-12

### clamp_cursors skips a hidden slot's kept window
- Location: carat/domain/tab_list.rb:252
- Why: a plugin view buffer shortened while its slot is hidden keeps a cursor past its last line until shown again. Folded into core-correctness-b.
- Fix: also walk each page's kept slot windows, with a case in test/editor_slots.rb.
- Also: test/editor_slots.rb
- Category: editor
- Added: 2026-11-17

### A hidden slot's window comes back with its cursor past the last line (sprint-18 sweep quality)
- Location: `carat/domain/tab_list.rb:252`; `carat/use_cases/windows/toggle_slot.rb:45`, `open_side_window.rb:36`.
- Why it matters: `clamp_cursors` skips windows kept in hidden slots, so a plugin view whose buffer shrank while hidden returns past its end.
- Fix outline: clamp kept slot windows too, or on show, with a `test/editor_slots.rb` row.
- Also: carat/use_cases/windows/toggle_slot.rb, test/editor_slots.rb
- Category: editor
- Added: 2026-11-18
