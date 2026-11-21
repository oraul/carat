# Backlog: carat/domain/command.rb

## Command has methods but no member pins

- Where: `carat/domain/command.rb` line 12, worked around in `Operate#big?` at `carat/use_cases/operate.rb` lines 187 to 189, at 38628bb (periodic quality). In the backlog items of the queue.
- Why it matters: the unpinned action forces a `.to_s` and a comment at its caller.
- Fix outline: pin each member and drop the workaround.
- Also: carat/use_cases/operate.rb
- Category: editor
- Added: 2026-11-09
