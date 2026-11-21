# Backlog: carat/domain/cell.rb

### Cell is a Struct though never changed
- Location: carat/domain/cell.rb:8
- Why: an immutable value view, which CLAUDE.md makes a Data subclass. Folded into ui-code-tidy.
- Fix: make it a Data subclass of code, width, hl.
- Also: CLAUDE.md
- Category: editor
- Added: 2026-11-17
