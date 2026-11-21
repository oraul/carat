# Backlog: carat/use_cases/actions/motion_handler.rb

## The action registration loop is copied five times

- Where: the `NAMES` and `DESCRIPTIONS` registration loop in `carat/use_cases/actions/motion_handler.rb` line 32 (twice), `search_handler.rb` (twice), and `text_object_handler.rb` (once), at 2f54bb5; `"Not implemented: "` is spelled in `dispatcher.rb` line 61, `find_match.rb` line 53, `selection_handler.rb` line 48, and `vim_pattern.rb` lines 274 and 460. Periodic quality at 2f54bb5. Queued in the backlog batches and `messages-tidy`. Raised again at be4b63a (now thirteen loops).
- Why it matters: a change to registration or to the refusal wording reaches one copy and misses the others, which the E-number lint cannot see.
- Fix outline: one `ActionTable` method registering a names list with its descriptions; one `Domain::Messages` function for the refusal prefix called from the four files.
- Raised again as "Action registration loops are copied five times": Where: `carat/use_cases/actions/motion_handler.rb:34` and `:41`, `text_object_handler.rb:35`, `search_handler.rb:35` and `:42`. Periodic quality. Raised again at be4b63a (now thirteen loops). Why it matters: five copies of one loop. Fix outline: one `ActionTable` method registering names and descriptions. Backlog batches (editing and keymap copies).
- Category: editor
- Added: 2026-11-10

### Twenty handler files copy the NAMES and DESCRIPTIONS loop
- Location: carat/use_cases/actions/motion_handler.rb:76, text_object_handler.rb, search_handler.rb, and about 20 more
- Why: one registration loop copied per kind. Folded into editing-dedup-a.
- Fix: ActionTable#register_all(names, handler, descriptions).
- Category: editor
- Added: 2026-11-17

### MotionHandler's class comment is garbled
- Location: carat/use_cases/actions/motion_handler.rb:10
- Why: "in a visual mode a motion moves the cursor end of the selection" misreads.
- Fix: "in a visual mode a motion moves the cursor, the moving end of the selection".
- Category: editor
- Added: 2026-11-17
