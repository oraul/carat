# Backlog: carat/domain/slot.rb

### Slot#clear forgets a kept hidden view window without dropping its folds
- Location: carat/domain/slot.rb:102
- Why: Slot#clear, also run by attach, forgets a kept hidden view window without drop_folds, so a plugin closing or replacing a hidden side window leaves its fold list tracked by the buffer (spec currency: windows, closing a window drops its folds; quality advisory).
- Fix: drop the kept window's folds before clear forgets it (in BufferList or the caller), with a test like the :tabclose slot assertion.
- Category: editor
- Added: 2026-11-19
