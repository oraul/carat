# Backlog: carat/domain/syntax_table.rb

### entry_at is public though only find uses it at carat/domain/syntax_table.rb:27 (sprint-30 sweep quality, note 79)

- Location: carat/domain/syntax_table.rb:27
- Why: entry_at is public though only find uses it
- Fix: move it under private (the typed accessor still pins the entry type)
- Category: editor
- Added: 2026-11-23
