# Backlog: carat/domain/replacement.rb

### Replacement.size restates the item walk of Replacement.expand
- Location: carat/domain/replacement.rb, `Replacement.size` beside `Replacement.expand` (files-ex-lows quality review).
- Why: the two walk the replacement's items the same way, one counting and one building, so a new item added to one and not the other would charge the budget for a size that is not built; test/domain_substitute.rb compares them over every item kind, which catches the drift but does not prevent it. Kept in files-ex-lows because a shared walk yielding items would cost a block or an item record per character on the substitute's hot path, under Spinel's rules for blocks and records.
- Fix: one item reader, `Replacement.item_at(text, i, n)` answering the item's kind and width as two typed readers, which `size` and `expand` both loop over; or `expand` taking a byte limit and answering "" past it, so `size` goes away.
- Also: test/domain_substitute.rb
- Category: editor
- Added: 2026-11-22
