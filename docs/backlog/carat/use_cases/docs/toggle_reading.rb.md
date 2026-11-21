# Backlog: carat/use_cases/docs/toggle_reading.rb

### ToggleReading's call takes a Command it never reads
- Location: carat/use_cases/docs/toggle_reading.rb:39
- Why: a use case's call takes the state and its operation's inputs, but call(state, command) never reads the Command (quality advisory, markdown-reading-a)
- Fix: make it call(state), as PinHover, and have DocsHandler pass only the state
- Category: editor
- Added: 2026-11-16
