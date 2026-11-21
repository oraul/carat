# Backlog: carat/use_cases/ex/window_command_handler.rb

### :new file and :vnew file drop their argument

- Location: carat/use_cases/ex/window_command_handler.rb:33. Sprint-6 sweep, quality. Queue item `ex-handlers-tidy`.
- Why: Vim edits the named file in the new window; carat opens an empty one silently.
- Fix outline: pass the argument, fresh only when it is empty, or answer E488, with a test.
- Category: editor
- Added: 2026-11-15
