# Backlog: carat/domain/message_history.rb

## MessageHistory stores levels nothing outside the tests reads

- Where: `carat/domain/message_history.rb` line 8, at the `feedback` change. Quality advisory of `feedback`.
- Why it matters: speculative generality: levels are kept per entry, but only tests read `level_at`, since `:messages` is not colored (`docs/compatibility.md`).
- Fix outline: drop the levels until `:messages` colors its listing, or use them for the listing's groups.
- Also: docs/compatibility.md
- Category: editor
- Added: 2026-11-09

## :messages drops the two-line unsaved-buffer refusal

- Where: `carat/domain/message_history.rb` line 29 (`add` drops any text holding a line feed), against `Messages.unsaved_buffer` in `carat/domain/messages.rb`, shown by `carat/use_cases/files/quit.rb`, at 31919d9. Periodic quality. Queue item `messages-tidy`.
- Why it matters: E37 with E162 is never kept, against `docs/compatibility.md` Messages and notifications (Error: Kept) and Neovim, whose `:messages` keeps both lines.
- Fix outline: keep each line of a shown message in the history (output-only text stays out), with a `test/editor_messages.rb` row for `:q` over a modified hidden buffer followed by `:messages`.
- Also: carat/domain/messages.rb, carat/use_cases/files/quit.rb, docs/compatibility.md, test/editor_messages.rb
- Category: editor
- Added: 2026-11-09
