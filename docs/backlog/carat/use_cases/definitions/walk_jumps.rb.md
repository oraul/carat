# Backlog: carat/use_cases/definitions/walk_jumps.rb

## The jump-tab hand-over is written twice

- Where: `carat/use_cases/definitions/walk_jumps.rb:51` and `carat/use_cases/definitions/visit_target.rb:82`. Periodic quality advisory at d0d783c.
- Why it matters: both read `tabless?` before the open, open, then hand the tab when `option.jumptab` says so; two copies of one rule drift.
- Fix outline: one shared place both use cases call, with the existing replace and keep rows unchanged. Queue item `definitions-tidy`.
- Also: carat/use_cases/definitions/visit_target.rb
- Category: editor
- Added: 2026-11-11

### Ctrl-O, Ctrl-I, and a jump to another file still refuse a modified buffer under hidden
- Location: `carat/use_cases/definitions/walk_jumps.rb:49` and `carat/use_cases/definitions/visit_target.rb:80`
- Why: with `option.hidden` on, the default, `:e`, the buffer commands, Ctrl-^, and `gt` leave a modified buffer hidden, but a jump list walk and a jump to a definition or other target in another file still answer E37, where Neovim lets them through; the brief named `:e` and the six buffer commands only, so the Difference in `docs/compatibility.md` names the gap.
- Fix: read `state.options.hidden` where each returns `Outcome.failure(Domain::Messages::E37)`, add the rows to the tables of `test/editor_jumps.rb` and `test/adapters_definitions.rb` with `:set nohidden` for the refusing ones, update the `jump-list` and `definitions` specs and drop the Difference's clause.
none
- Also: carat/use_cases/definitions/visit_target.rb, docs/compatibility.md, test/editor_jumps.rb, test/adapters_definitions.rb
- Category: editor
- Added: 2026-11-22
