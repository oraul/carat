# Tasks

## 1. Caret notation for names

- [x] 1.1 Add `Domain::ControlText.caret` and use it in `ListBuffers#name_of` and `Messages.unsaved_buffer`; proved by "A newline in a name in the listing" and "A newline in a name in E162" in `test/editor_buffers.rb`

## 2. Injected tab list

- [x] 2.1 Give `DeleteBuffer`, `ListBuffers`, and `CloseOtherWindows` a `tabs:` keyword, built with the one `TabList` in `EditorAssembly` and the test builders; proved by "the tab list" in `test/adapters_assembly.rb` and the buffer and window tests staying green

## 3. Comments

- [x] 3.1 Correct the stale comments of `close_tab.rb`, `close_other_tabs.rb`, `window_requests.rb`, `layout_node.rb`, and `buffer.rb`, and rewrap `scroll_request.rb:5` (comments only, no test)

## 4. Checks

- [x] 4.1 `make gates`, `make spec-validate`, `make lint`, `make docs-lint`, and the touched tests pass; the code map names `ControlText.caret`
