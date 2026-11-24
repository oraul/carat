# Backlog: openspec/specs/buffer-tabs/spec.md

### The scenario "The ascii icons give the ascii gem and separator" keeps a name that no longer fits
- Location: openspec/specs/buffer-tabs/spec.md, the scenario of that name
- Why: a MODIFIED block must keep the current scenario's title, so this change could not rename it though it now asserts no gem
- Fix: a later change renames the scenario in the spec, its test comment in test/adapters_tab_bar.rb, and its task text together
- Also: test/adapters_tab_bar.rb
- Category: pipeline
- Added: 2026-11-21

### Stale first-tab scenarios of the buffer-tabs spec
- Location: `openspec/specs/buffer-tabs/spec.md`, the scenarios "One file has the row under 2" and "The open file's modified mark follows its name under 2".
- Why: they read row 0 as "  • a.txt" and "  • a.txt ●", a dot before the name the tabs dropped with the file icon, so the spec disagrees with "A tab is a name and a mark, with no icon" and the shipped row.
- Fix: a delta spec modifying the requirement "Buffer tabs take the top row from two buffers or two tab pages" with "  a.txt" and "  a.txt ●", and the test that names them.
- Category: pipeline
- Added: 2026-11-24
