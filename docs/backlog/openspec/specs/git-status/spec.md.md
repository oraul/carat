# Backlog: openspec/specs/git-status/spec.md

### The git-status spec still says the segment shows on activation before any buffer opens (plugin-lazy-activate quality)
- Location: openspec/specs/git-status/spec.md:34, openspec/specs/plugin-host/spec.md:387
- Why: the scenario "The segment shows on activation" stays in the main spec though git_signs now activates only after the first frame and test/editor_git_signs.rb replaced its test with "Git runs only after the first frame"; the binding-conflict requirement still says "a plugin activated before it" while conflicts are now decided at prepare_all.
- Fix: add a git-status delta that removes or modifies the scenario, and reword the conflict requirement to "prepared".
- Also: openspec/specs/plugin-host/spec.md, test/editor_git_signs.rb
- Category: pipeline
- Added: 2026-11-18
