# Backlog: carat/use_cases/visual/extend_visual.rb

## ExtendVisual keeps a private tabstop_of with no caller

- Where: the private `tabstop_of` of `carat/use_cases/visual/extend_visual.rb` (line 53 at `start-screen`), uncalled since #30 split the visual use cases. Periodic quality at 5ac9674.
- Why it matters: dead code a reader must check before trusting the class's tab handling, and a second place a tab rule could drift.
- Fix outline: delete the method.
- Category: editor
- Added: 2026-11-05

### Requires never named in their files

- Location: carat/use_cases/visual/extend_visual.rb:6 (display_width), carat/domain/last_change.rb (position, display_width), carat/domain/operators.rb (registers, selection). Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: dead requires hide the real dependency graph.
- Fix outline: drop them and confirm with make test-build.
- Also: carat/domain/last_change.rb, carat/domain/operators.rb
- Category: editor
- Added: 2026-11-15

### ExtendVisual moves the cursor to read a text object (sprint-16 sweep quality)

- Location: carat/use_cases/visual/extend_visual.rb:55 (object_at), TextObjects.call at text_objects.rb:47.
- Why: it saves, moves, and restores the cursor around TextObjects, so a raise inside leaves the cursor moved.
- Fix outline: give TextObjects a position parameter and drop the save and restore.
- Category: editor
- Added: 2026-11-18

### Dead require (sprint-20 sweep quality, extend_visual.rb:6)

- Location: `carat/use_cases/visual/extend_visual.rb:6`
- Why: dead require: display_width is required but DisplayWidth is never named in the file
- Fix: drop the require_relative line
- Category: editor
- Added: 2026-11-19
