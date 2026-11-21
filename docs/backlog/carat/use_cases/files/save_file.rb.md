# Backlog: carat/use_cases/files/save_file.rb

## A write to another path is reported to the language server as a save

- Where: `SaveFile` in `carat/use_cases/files/save_file.rb` (line 52 at eb63fb4). Periodic quality at eb63fb4.
- Why it matters: `:w other_path` reports the buffer saved, so `didSave` goes out for a document whose own file was not written.
- Fix outline: report the save only when the written path is the buffer's own, with a row for `:w` to another path. Queued in `lsp-client-tidy`.
- Category: editor
- Added: 2026-11-07
