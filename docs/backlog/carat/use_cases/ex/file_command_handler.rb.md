# Backlog: carat/use_cases/ex/file_command_handler.rb

## carat/use_cases/ex/file_command_handler.rb:98 the ex handler resolves the alternate buffer itself (jump-motions, quality advisory)

- Location: carat/use_cases/ex/file_command_handler.rb:98
- Why: architecture section 5 has use cases orchestrate entities, but the ex handler now takes the BufferList and resolves the alternate buffer and its E194 and E499 refusals itself, beside SwitchBuffer's own alternate lookup.
- Fix outline: let OpenFile, or a small domain helper on BufferList returning the alternate path or the error, resolve '#', keeping the handler a forwarder.
- Category: editor
- Added: 2026-11-12
