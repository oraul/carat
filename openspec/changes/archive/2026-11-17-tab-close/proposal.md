# Proposal

## Why

A user-reported bug (part a of two of `tab-close`, a counted Sprint 13 backlog item by the user's decision). Under `option.gt buffers`, the default, the top row shows one tab per listed file buffer, yet nothing but `:bd` closes a buffer tab, and `:bd` closes windows. After `carat .`, opening a file from the explorer in a tab page leaves the unnamed startup buffer as a `[No Name]` tab that `:q` never closes; `:q` closes windows and tab pages but leaves every buffer tab in the row; and `:bd` on a buffer shown beside the explorer closes the file window, leaving the explorer alone, where `<Space>e` gives E444.

## What Changes

- `:q`, `:q!`, `:wq`, `:x`, and `<C-w>q` on the last window (a file window beside only side windows counting as the last) close the current buffer's tab when another listed file buffer exists, under `option.gt buffers`: the buffer leaves the list as `:bd` would and every window that showed it shows the next listed file buffer, or the one before; side windows stay. E37 still refuses `:q` on a modified buffer; `:q!` discards its changes. On the last listed file buffer every way quits as before. (`UseCases::Quit`)
- The unnamed, empty, unmodified startup buffer (buffer 1) leaves the list, the row, and `:ls` once a file opens in another window or tab page under `option.gt buffers`, every window that showed it showing the opened file; opening over it in its own window keeps the reuse. (`UseCases::OpenFile`, `Domain::BufferList#retire_startup`)
- `:bd`, `:bd N`, and `<leader>bd` keep the layout under `option.gt buffers`: every window that showed the deleted buffer shows the replacement (the next listed file buffer, the one before, or a new empty buffer) instead of closing. Under `option.gt tabpages` they close windows as before, except that the last file window of a tab page beside side windows shows the replacement instead of closing, so no tab page is left with only side windows. (`UseCases::DeleteBuffer`, `Domain::BufferList#withdraw`, `#close_windows_of`)
- The explorer toggle, through the plugin host's `close_scratch`, no longer ends on E444 when the side window is the editor's last window: a file window showing the first listed file buffer, or a new empty one, takes its place. (`UseCases::WindowRequests#close_scratch`)
- `docs/compatibility.md` rows for `:q` and `:bd` state the buffer-tab difference from Neovim.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-list`: deleting a buffer keeps the layout under `option.gt buffers` and never leaves a tab page with only side windows; the startup buffer leaves once a file opens elsewhere.
- `command-line-mode`: `:q` on the last window closes the buffer tab under `option.gt buffers` while another listed file buffer exists.
- `file-explorer`: the explorer toggle hides the tree also when it is the last window.

## Impact

- `carat/use_cases/files/quit.rb`, `carat/use_cases/buffers/delete_buffer.rb`, `carat/use_cases/files/open_file.rb`, `carat/use_cases/plugins/window_requests.rb`, `carat/domain/buffer_list.rb`.
- Tests: `test/editor_buffers.rb`, `test/editor_tabs.rb`, `test/editor_explorer.rb`, and other tests whose sessions depended on the old `:bd` and `:q` rules under the default `option.gt`, with their snapshots.
- README.md: changed, its `gt` and `gT` sentence now says that `:q` on the last window closes the buffer tab while another is left, that `:bd` closes it keeping every window, and that the empty startup buffer leaves the row once a file opens in another window or tab page.
- docs/architecture.md: unchanged, its `BufferList` entry's keep-or-release policy still holds and the file is at its byte budget; the codebase map names `withdraw` and `retire_startup`.
- CLAUDE.md: unchanged, no process change.
- docs/codebase-map.md: changed, the entries of `buffer_list.rb`, `delete_buffer.rb`, `quit.rb`, `open_file.rb`, and `window_requests.rb`; no file is added, moved, or removed.
- docs/compatibility.md: changed, the `:q` and `:bd` rows. docs/actions.md: unchanged, no action is added.

Outside the roadmap of `docs/architecture.md` section 12: a user-reported bug fix of Sprint 13's backlog lane.

## Out of scope

- Part b, `tab-close-b`: gt, gT, `:bn`, `:bp` with the focus in a side window, and the explorer's `t` under `option.gt buffers`.
- `:qa`, `<leader>qq`, and `<C-w>q` with a count closing a split keep their rules; `<leader>ls` (the slot toggle) keeps its E444 on a slot left alone.

Minor assumptions: the startup buffer is buffer 1 while it is still unnamed, empty, and unmodified, since the assembly lists it first; `:wq` and `:x` close the buffer tab after their write like `:q!` does, even when a write to another path left the buffer modified, since quitting would not check it either; the file window the explorer toggle opens in place of a last explorer window shows the first listed file buffer, or a new empty one when none is listed.
