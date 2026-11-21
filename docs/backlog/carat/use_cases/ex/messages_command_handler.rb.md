# Backlog: carat/use_cases/ex/messages_command_handler.rb

## Two ex handlers keep forwarding-only constructors

- Where: `carat/use_cases/ex/messages_command_handler.rb` line 14 and `carat/use_cases/ex/syntax_command_handler.rb` line 14 at 3895e21. Periodic quality. Queue item `messages-tidy`.
- Why it matters: dead code; each only forwards `spec` to `ExHandler#initialize`.
- Fix outline: delete both constructors.
- Also: carat/use_cases/ex/syntax_command_handler.rb
- Category: editor
- Added: 2026-11-09
