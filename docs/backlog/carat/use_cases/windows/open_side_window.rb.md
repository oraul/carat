# Backlog: carat/use_cases/windows/open_side_window.rb

## A plugin opening a view in an occupied slot releases another plugin's scratch buffer

- Where: `OpenSideWindow#reuse` in `carat/use_cases/windows/open_side_window.rb` line 69 at edaf2c2. Security Low (5) in `layout-slots`.
- Why it matters: the new view takes the slot window and `@buffers.release(old)` takes the other plugin's scratch buffer out of the list when no other window shows it, so plugin A can make plugin B's view, and B's later `set_scratch_lines` and `close_scratch`, fail; this crosses the plugin isolation boundary (availability only, no data or code exposure).
- Fix outline: release the old buffer only when it has the new one's owner; keep another plugin's buffer listed as a view of the slot (or refuse the request with a failure response), with an `editor_slots` test of two plugins sharing a slot.
- Category: security
- Added: 2026-11-09
