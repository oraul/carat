# Proposal

## Why

Part a of the backlog queue's `windows-buffers-tidy` item, split by the user's split rule since its four parts are independent and the last comparable tidy went over its medium budget. `:ls` (`carat/use_cases/buffers/list_buffers.rb:89`) and E162 (`carat/domain/messages.rb:18`) put a buffer's path into the message as it is, so a file name holding a newline breaks the message into lines it chose, forging a line of the listing or a second error (security Low, confidence 4). `DeleteBuffer`, `ListBuffers`, and `CloseOtherWindows` reach the tab list through `BufferList#tabs` while their siblings (`CloseWindow`, `CloseTab`, `CloseOtherTabs`) take an injected `tabs:`, so the assembly test cannot check they hold the one instance. Five comments describe behavior the code no longer has, and one comment line is 83 columns wide.

## What Changes

- A control character (C0 or DEL) in a buffer's name is shown in caret notation in `:ls` and in E162, as Neovim's `transstr` shows it: a newline is `^J`, so a name can no longer break either message into lines. The helper is `Domain::ControlText.caret`.
- `DeleteBuffer`, `ListBuffers`, and `CloseOtherWindows` take `tabs: Domain::TabList` beside `buffers:`, built with the one `TabList` in `EditorAssembly`; none reads `BufferList#tabs`.
- The stale comments are corrected: `CloseTab` and `CloseOtherTabs` (and the plugin host's `open_file` in `window_requests.rb`) say every file buffer stays listed, hidden, not only a modified one; `LayoutNode` and `Buffer#display_name` no longer call the row under a window, or the status bar and winbar, a status line.
- The 83-column comment of `scroll_request.rb` is rewrapped within its file's width.
- Tests: `test/editor_buffers.rb` lists a newline name in `:ls` and quits over it for E162; `test/adapters_assembly.rb` checks the three use cases hold the one tab list.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `buffer-list`: adds the requirement that a control character in a buffer's name is shown in caret notation in the listing and in E162.

## Impact

- `carat/domain/control_text.rb`, `carat/domain/messages.rb`, `carat/use_cases/buffers/list_buffers.rb`, `carat/use_cases/buffers/delete_buffer.rb`, `carat/use_cases/windows/close_other_windows.rb`, `carat/adapters/editor_assembly.rb`, and the comments of `close_tab.rb`, `close_other_tabs.rb`, `window_requests.rb`, `layout_node.rb`, `buffer.rb`, and `scroll_request.rb`.
- Tests: `test/editor_buffers.rb`, `test/adapters_assembly.rb`, `test/use_cases_ex.rb`, `test/use_cases_plugins.rb`, with their snapshots.
- README.md: unchanged, it describes neither the listing's row format nor E162.
- docs/architecture.md: unchanged, it names neither the listing's name format nor which use cases take the tab list.
- CLAUDE.md: unchanged, no process change.
- docs/codebase-map.md: changed, the `ControlText` entry names `caret`; no file is added, moved, or removed.
- docs/compatibility.md and docs/actions.md: unchanged, no command or action is added.

Outside the roadmap of `docs/architecture.md` section 12: a backlog tidy-up (T6 with a security Low) of sprint 12.

Backlog headings this change covers: "## :ls and E162 show a newline in a file name as a line break", "## DeleteBuffer and ListBuffers reach TabList through BufferList", "## Three window closers still say only a modified buffer stays listed", "## Two comments still call the row under a window its status line", "### A rewrapped comment in scroll_request.rb is still 83 columns wide". "## Five methods walk every window of every tab page" stays for `windows-buffers-walk`.

## Out of scope

- The one walk for the five methods (`carat/domain/tab_list.rb`, `carat/domain/buffer_list.rb`), queued as `windows-buffers-walk`.
- Escaping control characters in other messages that show a path (`:w`, `:e`, the status bar), which no finding names.

Minor assumptions: every C0 control and DEL is escaped, not only the newline, since that is Neovim's display of a name and a carriage return forges a line the same way; the comment lines the brief pinned at 68eb750 are found at their current lines (`close_tab.rb:10`, `close_other_tabs.rb:10`, `window_requests.rb:144`, `layout_node.rb:8`, `buffer.rb:190`).
