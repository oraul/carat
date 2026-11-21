# Backlog: carat/adapters/rc_config_gateway.rb

## Two classes declare a collaborator twice or by hand

- Where: `carat/adapters/rc_config_gateway.rb` line 33 (an `attr_reader` with its type beside a `# @rbs @files` line) and `carat/adapters/input_controller.rb` line 96 (a hand-written `decoder` reader) at b0dd342. Periodic quality. Queued in the backlog item batch.
- Why it matters: the pair #77 removed elsewhere; two declarations can drift.
- Fix outline: drop the `@rbs` line and use `attr_reader :decoder`.
- Also: carat/adapters/input_controller.rb
- Category: editor
- Added: 2026-11-07
