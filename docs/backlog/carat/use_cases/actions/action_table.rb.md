# Backlog: carat/use_cases/actions/action_table.rb

### ActionTable#register drops a duplicate silently

- Location: carat/use_cases/actions/action_table.rb:34 (sprint-4 sweep, quality advisory).
- Why: register returns false for a known name and all 68 callers ignore it, so a second registration vanishes.
- Fix: raise or note a startup problem; a test in test/use_cases_actions.rb.
- Also: test/use_cases_actions.rb
- Category: editor
- Added: 2026-11-14
