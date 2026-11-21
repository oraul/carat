# Backlog: carat/use_cases/actions/file_handler.rb

## The leader's write-quit-all copies the ex command's

- Where: `write_quit_all` in `carat/use_cases/actions/file_handler.rb` (line 60 at `leader-layout`) repeats `FileCommandHandler#write_quit_all` in `carat/use_cases/ex/file_command_handler.rb` (line 85) line for line. Quality advisory of `leader-layout`.
- Why it matters: `:wqa` and leader `q w` agree by copy rather than by construction, against `docs/architecture.md` section 5 (shared logic stays a use case the others call), so a fix to one can miss the other.
- Fix outline: extract a `WriteQuitAll` use case over `SaveAll` and `QuitAll`, build it once in `EditorAssembly`, and inject it into both handlers.
- Also: carat/use_cases/ex/file_command_handler.rb, docs/architecture.md
- Category: editor
- Added: 2026-11-05

## An unknown file action variant writes every buffer and quits

- Where: `carat/use_cases/actions/file_handler.rb` line 37: removing `file.find` turned the case's `else` into the `:write_all` branch. Periodic quality at 186ddfb, blocking, queued in `periodic-blockers-b`.
- Why it matters: a new or misspelled variant registered in `self.register` silently writes every buffer and quits; a latent correctness defect.
- Fix outline: restore `when :write_all then write_quit_all(state)` and let no variant fall through to it, with a row.
- Category: editor
- Added: 2026-11-10
