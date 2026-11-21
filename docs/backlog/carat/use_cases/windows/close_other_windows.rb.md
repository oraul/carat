# Backlog: carat/use_cases/windows/close_other_windows.rb

## CloseOtherWindows reaches the tabs through the buffer list

- Where: `carat/use_cases/windows/close_other_windows.rb:62` (`@buffers.tabs`). Periodic quality at ce6abdb, the part of its window-copies finding no other entry names; queue item `slots-tidy`.
- Why it matters: a second path to the one tab list escapes `test/adapters_assembly.rb`.
- Fix outline: inject `tabs:` and assert it in `test/adapters_assembly.rb`.
- Also: test/adapters_assembly.rb
- Category: editor
- Added: 2026-11-10

## Folded windows-tabs-tidy close_window finding is in neither lane queue

- Location: docs/backlog.md:6647 (the folded windows-tabs-tidy finding); carat/use_cases/windows/close_other_windows.rb:10
- Why: the close_window clear of tab.previous never shipped and the comment at close_other_windows.rb:10 is false, yet the finding is in neither lane queue while groom removed the old entry "CloseOtherWindows clears tab.previous a second time" as fixed by windows-tabs-tidy, so the gap can sit unseen.
- Fix: have the planner add it to the windows-buffers-tidy item (close_other_windows.rb:10, buffer_list.rb:369) or queue it alone.
- Category: editor
- Added: 2026-11-17
