# Backlog: carat/use_cases/buffers/delete_buffer.rb

## :bd N deletes a buffer a jump left unlisted

- Where: `carat/use_cases/buffers/delete_buffer.rb:29`, against the class comment (line 16). Periodic quality advisory at d0d783c.
- Why it matters: the comment promises E516 for a number of no listed file buffer, as Neovim answers.
- Fix outline: refuse an unlisted target with E516 when a number is given, with a `test/editor_buffers.rb` row after a replace jump. Queue item `buffer-list-tidy`.
- Also: test/editor_buffers.rb
- Category: editor
- Added: 2026-11-11
