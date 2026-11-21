# Backlog: carat/domain/buffer_list.rb

## BufferList keeps any_modified? and number_of with no production caller

- Where: `any_modified?` (line 115 at cd87445) in `carat/domain/buffer_list.rb`, still named in the map's `buffer_list.rb` line, and `number_of` (line 61), whose only caller is `test/domain_buffer_list.rb` line 169. Quality advisory of `buffer-list`; reworded by the periodic quality review at cd87445.
- Why it matters: `Quit` and `QuitAll` now use `first_unsaved`, so `any_modified?` is dead code, and `number_of` returns a list position that is no longer the buffer number, which misleads a future caller.
- Fix outline: remove both, use `modified_buffer.nil?` in the tests, and drop `any_modified?` from the map. Queued in `docs-index`.
- Also: test/domain_buffer_list.rb
- Category: editor
- Added: 2026-11-05

## BufferList#first_unsaved takes a boolean flag argument

- Where: `first_unsaved(hidden_only)` in `carat/domain/buffer_list.rb` (line 124 at `buffer-list`), called by `Quit` and `QuitAll`. Quality advisory of `buffer-list`.
- Why it matters: a flag argument hides two behaviors behind one name; `Quit` reaches it with one file window whose buffer `:quit` already checked, so `first_unsaved(false)` equals `hidden_modified` there.
- Fix outline: have `Quit` call `@buffers.hidden_modified` and drop the parameter, leaving `first_unsaved` for `QuitAll`. Queued as `buffer-list-structure` in `docs/queue.md`.
- Category: editor
- Added: 2026-11-05

## BufferList#step_from is hard to verify and exposes file_count for it

- Where: `step_from` (line 145 at `buffer-list`) and `file_count` (line 169) in `carat/domain/buffer_list.rb`. Quality advisory of `buffer-list`.
- Why it matters: a modulo shortcut combined with a sentinel-reset loop makes `:bn` and `:bp` with a count hard to check by reading, and `file_count` is public only for it.
- Fix outline: gather the file-buffer indices once and index them modulo their count from the target's position, and make `file_count` private or fold it in, keeping the `test/domain_buffer_list.rb` rows. Since `bars`, `BufferList#tab_row?` and the buffer tabs also count file buffers, so `file_count` stays public or gives way to a shared walk. Queued as `buffer-list-structure` in `docs/queue.md`.
- Also: test/domain_buffer_list.rb
- Category: editor
- Added: 2026-11-05

## Closing a tab page's last window keeps its hidden slots' views

- Where: `close_window` in `carat/domain/buffer_list.rb` line 280, unlike `close_tab` at line 304, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: `:q` or `:close` on the only window of a tab page with a hidden sidebar removes the tab page through `remove_tab` without releasing the slot's views, so the plugin's scratch buffer stays listed and unshown.
- Fix outline: route the single-leaf path through `close_tab` or one shared tab-removal helper that releases kept slot buffers, with an `editor_slots` row closing the tab page by `:q`.
- Category: editor
- Added: 2026-11-09

## BufferList's comments and hand_tab's guards predate unlisted buffers

- Where: `carat/domain/buffer_list.rb:8`, `:59`, `:65`, `:77`, `:279`; `docs/architecture.md:132`. Periodic quality.
- Why it matters: the comments call every buffer held listed; `hand_tab`'s three guards and its reorder have no domain row, and its modified guard is unreachable behind E37.
- Fix outline: reword the comments and the architecture entry; a table row per guard and for a target before and after the buffer left; state the modified guard as an invariant or drop it. Queue item `buffer-list-tidy`.
- Also: docs/architecture.md
- Category: editor
- Added: 2026-11-10

## first_file and last_file are one scan written twice

- Where: `carat/domain/buffer_list.rb:131`; `carat/use_cases/buffers/switch_buffer.rb:36`. Quality advisory of `jump-list`.
- Why it matters: two copies of one scan, and `SwitchBuffer#call` re-tests the target in a ternary inside the `elsif` that already chose it.
- Fix outline: one `BufferList` method taking the direction, or separate `:first` and `:last` branches in `SwitchBuffer`. Queue item `buffer-list-tidy`.
- Also: carat/use_cases/buffers/switch_buffer.rb
- Category: editor
- Added: 2026-11-10

## BufferList's comments call its unlisted buffers listed, and the unsaved rule has ten copies

- Where: `carat/domain/buffer_list.rb:8` (class comment, `for_path`, `with_id`, and map area 8 say listed buffers, though `hand_tab` leaves unlisted ones in it; OpenFile names the result listed); `modified? && !scratch?` at `walk_jumps.rb:37`, `visit_target.rb:80`, `quit.rb:42` and `:51`, `save_all.rb:31`, `switch_buffer.rb:43`, `list_buffers.rb:88`, `window_requests.rb:163`, `buffer_list.rb:108` and `:233`. Periodic quality at 9a92265.
- Why it matters: callers read a list as listed buffers only; the rule changes in one place and not the others.
- Fix outline: reword to buffers listed or not, and one Buffer predicate with a domain row. Queue item `buffer-list-tidy`.
- Category: editor
- Added: 2026-11-10

## BufferList decides reuse twice, and :e and :x ignore the scratch rule

- Where: `carat/domain/buffer_list.rb:303` (`enter` repeats `load`'s reuse test at 283); `carat/use_cases/ex/file_command_handler.rb:95` (`:e` refuses an edited scratch buffer with E37) and :77 (`:x` tries to write it). Periodic quality at bd86828.
- Why it matters: two reuse rules can drift; the nine copies of `modified? && !scratch?` are how two sites missed it.
- Fix outline: one reuse decision and one unsaved predicate at every site, with a `test/editor_cmdline.rb` row for `:e` from an edited scratch window. Queue item `buffer-list-tidy`.
- Also: carat/use_cases/ex/file_command_handler.rb, test/editor_cmdline.rb
- Category: editor
- Added: 2026-11-11

### BufferList#enter duplicates the jump guard of Window#record_jump (`jump-motions` quality advisory)

- Location: `carat/domain/buffer_list.rb:315` (`enter`).
- Why it matters: enter pushes old.id, row, and col itself behind an 'unless old.id == 0' guard that the new Window#record_jump already holds, so the two jump-recording paths can drift apart.
- Fix outline: replace the push with 'current.record_jump unless target.id == 0 && reusable?(old)', keeping the editor_jumps cases green.
- Category: editor
- Added: 2026-11-12

### lone_file_window? is evaluated once per window instead of once per tab page

- Location: carat/domain/buffer_list.rb:423
- Why: `lone_file_window?(tabs.tab_at(t))` runs for every window of the inner loop though it depends only on the tab page, so the walk repeats a per-tab-page test once per window (performance).
- Fix: compute it once per tab page before the window loop and reuse the value inside it.
- Category: editor
- Added: 2026-11-17

### lone_file_window? reads only the tab page yet lives on BufferList (sprint-13 quality)
- Location: carat/domain/buffer_list.rb:475, :423; carat/use_cases/files/quit.rb:87.
- Why: lone_file_window?(page) reads only file_window_count and layout.leaf_count, Quit#beside_side_windows? restates the rule with its own loop, and :423 evaluates it per window though it depends only on the tab page.
- Fix: TabPage#lone_file_window? called by Quit, DeleteBuffer, and close_windows_of, once per tab page. Queue item `windows-buffers-walk`.
- Also: carat/use_cases/files/quit.rb
- Category: editor
- Added: 2026-11-17

### BufferList#withdraw saves a cursor no one reads (sprint-13 quality)
- Location: carat/domain/buffer_list.rb:449.
- Why: remember(window) runs on target just before it leaves the list, and neither alternate_of nor a reopen reaches a removed buffer: a dead write.
- Fix: drop the remember call, keep show plus restore. Queue item `windows-buffers-walk`.
- Category: editor
- Added: 2026-11-17

### close_tab walks the tab page's slots twice
- Location: carat/domain/buffer_list.rb:408
- Why: close_tab collects the kept view windows' buffers (lines 407-412) and again walks the slots in drop_slot_folds (line 413), a duplication (quality advisory).
- Fix: drop each kept view window's folds in the existing loop and call drop_slot_folds only from close_window.
- Category: editor
- Added: 2026-11-19

### Carat/domain/undo_tree.rb (sprint-20 sweep quality, buffer_list.rb:382,)

- Location: `carat/domain/buffer_list.rb:382,`
- Why: carat/domain/undo_tree.rb:111, carat/use_cases/ex/ex_table.rb:86, carat/domain/window.rb:182 public helpers used only inside their own class: drop_slot_folds, head_of, handler_at, and scroll_folded have no outside caller
- Fix: move them under private (BufferList and UndoTree already have private sections) and drop scroll_folded from the area 11 map entry
- Also: carat/domain/undo_tree.rb, carat/use_cases/ex/ex_table.rb, carat/domain/window.rb
- Category: editor
- Added: 2026-11-19
