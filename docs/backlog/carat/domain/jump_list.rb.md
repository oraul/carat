# Backlog: carat/domain/jump_list.rb

## A backlog entry still names a fixed JumpList#step defect

- Where: the `docs/backlog.md` entry that says `JumpList#step` pushes before the range check (line 3367 at d0d783c); `carat/domain/jump_list.rb:59-60` now returns early and `test/domain_jump_list.rb:78` pins it. Periodic quality advisory at d0d783c.
- Why it matters: a stale clause sends a later change after a fixed defect.
- Fix outline: drop that clause from the entry's fix outline, in the periodic review's backlog step. Queue item `periodic-council`.
- Also: test/domain_jump_list.rb
- Category: editor
- Added: 2026-11-11
