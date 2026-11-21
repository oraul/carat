# Backlog: carat/use_cases/files/delete_path.rb

## A buffer a jump left unlisted turns modified yet stays hidden

- Where: `carat/use_cases/files/delete_path.rb:64` (`mark_deleted`), `carat/use_cases/plugins/buffer_requests.rb:127`, against `carat/use_cases/buffers/list_buffers.rb:66`. Periodic quality.
- Why it matters: the buffer is hidden from the tab row, `:ls`, and `:ls +`, while `:wa` silently writes the deleted file back and `:q` refuses on a buffer the user cannot see.
- Fix outline: a buffer is listed again when it becomes modified, as Neovim's text edits set `buflisted`, with an editor row. Queue item `periodic-blockers-b`.
- Also: carat/use_cases/plugins/buffer_requests.rb, carat/use_cases/buffers/list_buffers.rb
- Category: editor
- Added: 2026-11-10
