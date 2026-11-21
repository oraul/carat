# Backlog: carat/use_cases/buffers/buffer_request.rb

## BufferRequest's :current target exists only to return no outcome

- Where: `carat/use_cases/buffers/buffer_request.rb` (line 5 at `buffer-list`), `SwitchBuffer` in `carat/use_cases/buffers/switch_buffer.rb` (line 29), and its one producer in `BufferCommandHandler` (line 66). Quality advisory of `buffer-list`.
- Why it matters: a request target with no behavior widens the use case's input for one handler's empty-argument case.
- Fix outline: return `Outcome.none` in `BufferCommandHandler#number` for `:b` without a number and drop `:current` from `BufferRequest` and `SwitchBuffer`. Queued as `buffer-list-tidy` in `docs/queue.md`.
- Also: carat/use_cases/buffers/switch_buffer.rb
- Category: editor
- Added: 2026-11-05
