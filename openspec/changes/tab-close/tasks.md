# Tasks

## 1. The withdraw primitive and the startup buffer

- [ ] 1.1 Add `BufferList#withdraw` and `#retire_startup` (`carat/domain/buffer_list.rb`) and call `retire_startup` from `OpenFile#call` under `gt_follows_buffers?`; proved by "A file opened in a tab page retires the startup buffer", "A file opened in a split retires the startup buffer", and "Under tab pages the startup buffer stays" in `test/editor_tabs.rb`

## 2. :q closes the buffer tab

- [ ] 2.1 Close the buffer tab in `Quit#call` (`carat/use_cases/files/quit.rb`) under `gt_follows_buffers?`; proved by the "Quit closes the buffer tab" scenarios in `test/editor_buffers.rb` and "Quit beside the explorer closes the buffer tab" in `test/editor_explorer.rb`, the hidden-buffer quit rows moved to `option.gt tabpages`

## 3. :bd keeps the layout

- [ ] 3.1 Show the replacement in every window in `DeleteBuffer#call` (`carat/use_cases/buffers/delete_buffer.rb`) under `gt_follows_buffers?`, and keep the last file window beside side windows under `tabpages` (`BufferList#close_windows_of`); proved by the delete scenarios in `test/editor_buffers.rb` and `test/editor_explorer.rb`
- [ ] 3.2 Replace a last scratch window with a file window in `WindowRequests#close_scratch` (`carat/use_cases/plugins/window_requests.rb`); proved by "The explorer toggle in a lone tree opens a file window" in `test/editor_explorer.rb`

## 4. Docs and checks

- [ ] 4.1 State the buffer-tab difference in the `:q` and `:bd` rows of `docs/compatibility.md`
- [ ] 4.2 `make gates`, `make spec-validate`, `make lint`, `make docs-lint`, and the touched tests pass
