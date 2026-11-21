# Backlog: carat/use_cases/windows/toggle_slot.rb

## ToggleSlot repeats the leaf close and the kept-slot placement

- Where: the hide branch of `carat/use_cases/windows/toggle_slot.rb` lines 35 to 37, repeating `BufferList#close_window` (`carat/domain/buffer_list.rb` lines 282 to 284), and the kept-slot restore at lines 40 and 48 to 49, repeating `carat/use_cases/windows/open_side_window.rb` lines 35 to 38; the `current` lookup again after `place_slot` at lines 47 and 50, at edaf2c2. Quality advisories in `layout-slots`, raised three times. Raised again at ce6abdb (`toggle_slot.rb:30` against `buffer_list.rb:282` and `open_side_window.rb:27`; periodic quality), queue item `slots-tidy`: a `TabPage#remove_leaf(id)` and one re-show step.
- Why it matters: two copies of closing a leaf (layout close, current to the taker's first leaf, previous forgotten) and of placing a kept slot (kept and listed, `place_slot` at its size, `hidden = false`) drift apart; the second `current` lookup is dead, since `attach` and `panel_target` never renumber existing leaves.
- Fix outline: one `TabPage#close_leaf(id)` called by `ToggleSlot` and `BufferList#close_window`, one method that places a kept slot and answers the leaf or -1, called by both use cases, and drop the `current` local and its reassignment.
- Also: carat/domain/buffer_list.rb, carat/use_cases/windows/open_side_window.rb
- Category: editor
- Added: 2026-11-09
