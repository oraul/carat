# Backlog: carat/use_cases/ex/file_command_handler.rb

## carat/use_cases/ex/file_command_handler.rb:98 the ex handler resolves the alternate buffer itself (jump-motions, quality advisory)

- Location: carat/use_cases/ex/file_command_handler.rb:98
- Why: architecture section 5 has use cases orchestrate entities, but the ex handler now takes the BufferList and resolves the alternate buffer and its E194 and E499 refusals itself, beside SwitchBuffer's own alternate lookup.
- Fix outline: let OpenFile, or a small domain helper on BufferList returning the alternate path or the error, resolve '#', keeping the handler a forwarder.
- Category: editor
- Added: 2026-11-12

### inconsistency: :e refuses with E37 for any modified current at carat/use_cases/ex/file_command_handler.rb:110 (sprint-26 sweep quality, note 28)

- Location: carat/use_cases/ex/file_command_handler.rb:110
- Why: inconsistency: :e refuses with E37 for any modified current buffer, a scratch plugin buffer included under option.hidden off, while SwitchBuffer (carat/use_cases/buffers/switch_buffer.rb:80) exempts scratch buffers
- Fix: one Buffer predicate for unsaved work (modified? and not scratch?) used by both, with an editor_buffers row for :e from a modified scratch buffer under nohidden
- Also: carat/use_cases/buffers/switch_buffer.rb
- Category: editor
- Added: 2026-11-22
