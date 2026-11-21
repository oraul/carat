# Backlog: carat/use_cases/execute_command_line.rb

## The palette runs ex commands that need an argument bare

- Where: `carat/use_cases/execute_command_line.rb` line 91 at d828abb. Quality advisory in `discoverability`.
- Why it matters: picking `:edit`, `:buffer`, `:substitute`, or `:set` in the palette runs it without an argument and only reports an error.
- Fix outline: for a command that takes an argument, leave `:name ` on the command line instead of running it, with a row in `test/editor_palette.rb`, or note the behavior in `docs/compatibility.md`.
- Also: test/editor_palette.rb, docs/compatibility.md
- Category: editor
- Added: 2026-11-09

## A plugin prompt opened over the command palette is answered by the palette

- Where: `carat/use_cases/execute_command_line.rb` line 57 and `UiRequests#prompt` in `carat/use_cases/plugins/ui_requests.rb` line 64, at 38628bb (periodic security Low (3)). Queued in `discoverability-tidy`.
- Why it matters: with the palette active, Enter runs the palette's selected entry, an ex command or action matched by the prompt's text, instead of answering the prompt, and the prompt stays open in normal mode.
- Fix outline: refuse a prompt while the palette is active or close the palette first, with a row in `test/editor_palette.rb`.
- Also: carat/use_cases/plugins/ui_requests.rb, test/editor_palette.rb
- Category: security
- Added: 2026-11-09
