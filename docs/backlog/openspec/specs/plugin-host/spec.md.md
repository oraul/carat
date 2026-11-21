# Backlog: openspec/specs/plugin-host/spec.md

### plugin-host spec lacks a scenario for cutting before a character
- Location: openspec/specs/plugin-host/spec.md (from the archived change git-signs-status-a, delta spec line 4)
- Why: the requirement cuts before a character the limit would split, but no scenario names that and the test at test/drivers_process_runner.rb:62 names none.
- Fix: add a scenario such as 'Long output is cut before a character' and label the driver test with it.
- Also: test/drivers_process_runner.rb
- Category: pipeline
- Added: 2026-11-16
