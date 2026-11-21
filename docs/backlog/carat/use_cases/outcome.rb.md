# Backlog: carat/use_cases/outcome.rb

### Outcome.success("") is still built at 23 sites (sprint-18 sweep quality)
- Location: `carat/use_cases/outcome.rb:30`; `carat/use_cases/files/quit.rb`, `windows/split_window.rb`, `open_side_window.rb`, `plugins/plugin_router.rb`.
- Why it matters: `Outcome.none` exists so a key allocates nothing.
- Fix outline: return `Outcome.none`.
- Also: carat/use_cases/files/quit.rb
- Category: editor
- Added: 2026-11-18
