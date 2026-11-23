# Backlog: carat/domain/slot.rb

### Slot#clear forgets a kept hidden view window without dropping its folds
- Location: carat/domain/slot.rb:102
- Why: Slot#clear, also run by attach, forgets a kept hidden view window without drop_folds, so a plugin closing or replacing a hidden side window leaves its fold list tracked by the buffer (spec currency: windows, closing a window drops its folds; quality advisory).
- Fix: drop the kept window's folds before clear forgets it (in BufferList or the caller), with a test like the :tabclose slot assertion.
- Category: editor
- Added: 2026-11-19

### The right sidebar and the panel keep their title rows, and the tab row still spans a right sidebar
- Location: `carat/domain/slot.rb`, `headed?`; `carat/adapters/frame_presenter.rb`, `paint_tab_head`
- Why: the brief's head and one-view rule are the left sidebar's; with the explorer on the right (`plugin.explorer.side right`) the tab row starts at column 0 and runs over the sidebar's width, and the sidebar keeps its `explorer` title row.
- Fix: decide the right sidebar's look in a design item (head, or the tab row ending at its edge), then extend `headed?` and `paint_tab_head` to it with a test.
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-23
