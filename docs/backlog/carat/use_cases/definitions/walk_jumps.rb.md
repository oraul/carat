# Backlog: carat/use_cases/definitions/walk_jumps.rb

## The jump-tab hand-over is written twice

- Where: `carat/use_cases/definitions/walk_jumps.rb:51` and `carat/use_cases/definitions/visit_target.rb:82`. Periodic quality advisory at d0d783c.
- Why it matters: both read `tabless?` before the open, open, then hand the tab when `option.jumptab` says so; two copies of one rule drift.
- Fix outline: one shared place both use cases call, with the existing replace and keep rows unchanged. Queue item `definitions-tidy`.
- Also: carat/use_cases/definitions/visit_target.rb
- Category: editor
- Added: 2026-11-11
