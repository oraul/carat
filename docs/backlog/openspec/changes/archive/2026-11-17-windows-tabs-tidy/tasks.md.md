# Backlog: openspec/changes/archive/2026-11-17-windows-tabs-tidy/tasks.md

### The windows-tabs-tidy artifacts and a comment describe a close_window clear that never shipped
- Location: openspec/changes/archive/2026-11-17-windows-tabs-tidy/tasks.md:13, design.md ('The previous window never names the current one'), carat/use_cases/windows/close_other_windows.rb:10, carat/domain/buffer_list.rb:369
- Why: task 3.1 (marked done) and the design describe a BufferList#close_window clear of tab.previous when it equals the new current window and a test 'closing into the previous window clears it', neither in the diff (buffer_list.rb:369 unchanged), so <C-w>s<C-w>c still leaves previous == current and the new comment 'the window kept is never the previous' is false; the design also gives the integer minimum as -4_611_686_018_427_387_903 - 1 where the test uses -2^63.
- Fix: implement the close_window clear with its editor_windows row, or correct the comment to the shipped behavior and record the design's integer minimum as -2^63.
- Also: carat/use_cases/windows/close_other_windows.rb, carat/domain/buffer_list.rb
- Category: pipeline
- Added: 2026-11-17
