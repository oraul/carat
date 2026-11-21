# Backlog: carat/adapters/sgr_table.rb

## Comments name only the cursor-line layer

- Where: the `SgrTable` class comment in `carat/adapters/sgr_table.rb` line 8, `Frame`'s comment in `carat/domain/frame.rb` line 13, and `docs/architecture.md` line 260, at the `quick-docs-styles` change. Quality advisory in `quick-docs-styles`.
- Why it matters: cells and sequences now also carry `Highlight::FLOAT_LAYER`, so the comments mislead a reader adding a layer.
- Fix outline: mention the float layer in all three.
- Also: carat/domain/frame.rb, docs/architecture.md
- Category: editor
- Added: 2026-11-09

### carat/adapters/sgr_table.rb:70: the helpers basic, color (81), level (113), and distance (sprint-22 sweep quality)

- Location: `carat/adapters/sgr_table.rb:70`
- Why: the helpers basic, color (81), level (113), and distance (124) are public class methods used only inside SgrTable
- Fix: private_class_method them, keeping from_theme, sequence, and index_256 public
- Category: editor
- Added: 2026-11-20
