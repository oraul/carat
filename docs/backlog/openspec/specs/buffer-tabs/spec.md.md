# Backlog: openspec/specs/buffer-tabs/spec.md

### The scenario "The ascii icons give the ascii gem and separator" keeps a name that no longer fits
- Location: openspec/specs/buffer-tabs/spec.md, the scenario of that name
- Why: a MODIFIED block must keep the current scenario's title, so this change could not rename it though it now asserts no gem
- Fix: a later change renames the scenario in the spec, its test comment in test/adapters_tab_bar.rb, and its task text together
- Also: test/adapters_tab_bar.rb
- Category: pipeline
- Added: 2026-11-21
