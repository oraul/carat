# Design

## Context

`Options#gt_follows_buffers?` (`option.gt buffers`, the default) makes the top row a row of buffer tabs, one per listed file buffer, but the window rules of `:q` and `:bd` are still Neovim's, which close windows and tab pages. The fixes make a buffer tab the thing `:q` and `:bd` close under that option and leave `option.gt tabpages` as it was, apart from one guard: no tab page is left with only side windows.

## Decisions

### One withdraw primitive

`BufferList#withdraw(target, other)` lists `other`, shows it in every layout window of every tab page that shows `target` (each window remembering its cursor in `target` and taking `other`'s remembered cursor, as `load` does), and removes `target` from the list. `Quit`, `DeleteBuffer`, and the startup-buffer rule all use it, so the three agree on what closing a buffer tab means.

### :q

In `Quit#call`, past the float and the multi-window rules and the E37 check, under `gt_follows_buffers?` with a current buffer that is a listed file buffer, `replacement_for(current)` non-nil means another buffer tab exists: `withdraw(current, other)` and success. `:q!` and `:written` reach the same branch, so `:q!` discards the changes and the hidden-buffer check runs only when the editor would end. The options come from `state.options`, as `TabHandler` reads them.

### The startup buffer

`BufferList#retire_startup(opened)`: when `opened` is a file buffer and buffer 1 is listed and still unnamed, empty, unmodified, and not scratch, `withdraw(startup, opened)`. `OpenFile#call` calls it after it shows a file under `gt_follows_buffers?`; every host open path (`:e`, `:tabe`, `:sp file`, the plugin host's `open_file`, `open_in_split`, `open_in_tab`) goes through `OpenFile`. Opening over the startup buffer in its own window already reused it, so it is no longer listed there and nothing happens. Buffer 1 is the startup buffer because the assembly lists it first; once a file reused it, buffer 1 has a path and the rule no longer applies.

### :bd

Under `gt_follows_buffers?`, `DeleteBuffer` closes no window: when any window shows `target`, it withdraws it in favour of `replacement_for(target)` or a new empty buffer, then removes it. Under `tabpages` it keeps Neovim's order, but `close_windows_of` and the loop closing the current window skip a window that is the last file window of its tab page while side windows share it (`TabPage#file_window_count` is 1 and the layout has more leaves); the windows still showing `target` afterwards take the replacement through `withdraw`.

### The explorer toggle

`WindowRequests#close_scratch` gave E444 when the scratch window was the editor's last. Now it splits that window vertically, shows the first listed file buffer (`file_at(1)`) or a new empty buffer in the new window, focuses it, and closes the scratch window. A split that does not fit still gives E36 as `SplitWindow` does.

## Risks

- Sessions in existing tests that relied on `:bd` closing windows or on `:q` quitting over another listed buffer under the default option change their result; those tests either move to `option.gt tabpages` or state the new layout.
- The startup rule is keyed on buffer 1; a later empty buffer is never retired, which keeps `:new` and `:tabnew` buffers as they are.
