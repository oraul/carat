# Backlog: carat/domain/messages.rb

### messages.rb names ControlText without requiring it

- Location: carat/domain/messages.rb:18 (sprint-12 review and sweep, quality).
- Why: unsaved_buffer calls ControlText.caret with no require_relative of control_text, the only file under carat/ doing so; it compiles only through the order of carat.rb.
- Fix outline: add require_relative "control_text" at the top of messages.rb.
- Also: carat.rb
- Category: editor
- Added: 2026-11-17

### Unsaved_buffer calls ControlText.caret with no require_relative of (sprint-20 sweep quality, messages.rb:21)

- Location: `carat/domain/messages.rb:21`
- Why: unsaved_buffer calls ControlText.caret with no require_relative of control_text, so it compiles only through carat.rb's order, unlike every other domain file, which requires what it names
- Fix: add require_relative "control_text"
- Also: carat.rb
- Category: editor
- Added: 2026-11-19
