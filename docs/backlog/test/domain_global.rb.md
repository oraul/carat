# Backlog: test/domain_global.rb

### test-one cannot compile test/domain_global.rb alone

- Location: test/domain_global.rb, its standalone compile failing at carat/use_cases/history/list_undo.rb:27 and carat/use_cases/history/walk_history.rb:168 (a finding the core-correctness contributor handed over that never reached the backlog; its retrospective).
- Why: make test-one T=test/domain_global.rb does not compile though the whole runner passes, so the global command's tests cannot be checked alone; 1 of 4 handed findings of core-correctness was lost.
- Fix outline: reproduce with make test-one, name the typing the standalone program loses at those two lines, and type it or record the pitfall in docs/spinel-notes.md, accepted when the standalone compile passes. Queue item `tools-docs-tidy`.
- Also: carat/use_cases/history/list_undo.rb, carat/use_cases/history/walk_history.rb, docs/spinel-notes.md
- Category: code-quality
- Added: 2026-11-15
