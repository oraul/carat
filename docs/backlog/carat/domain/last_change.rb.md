# Backlog: carat/domain/last_change.rb

## A long insert copies its typed text on every key

- Where: `carat/domain/last_change.rb` line 117 (add_text) and line 137 (add_action) at c1b3a12 (periodic quality). Queued in `insert-copy`.
- Why it matters: each typed key rebuilds the session's typed string, so a long insert costs quadratic bytes on the typing hot path.
- Fix outline: append to a fresh string started per session and hand the '.' register a copy, with a long-insert case and `insert` held at 35.0.
- Category: editor
- Added: 2026-11-09

## LastChange#resumed? changes state

- Where: `carat/domain/last_change.rb` line 175 at 38628bb (periodic quality). In the backlog items of the queue.
- Why it matters: the predicate resets `next_visual`, starts a recording, and sets `recording`, against the rule that a predicate answers a question.
- Fix outline: a resume step called by `add_text` and `add_action`, and a plain recording check.
- Category: editor
- Added: 2026-11-09

### Dead requires (sprint-20 sweep quality, last_change.rb:2)

- Location: `carat/domain/last_change.rb:2`
- Why: dead requires: position (:2) and display_width (:5) are required but no Position or DisplayWidth is named in the file
- Fix: drop both require_relative lines
- Category: editor
- Added: 2026-11-19

### Naming (sprint-20 sweep quality, last_change.rb:175)

- Location: `carat/domain/last_change.rb:175`
- Why: naming: the predicate resumed? has side effects (clears next_visual, starts a new mode.insert change, sets recording)
- Fix: split it into a command that resumes after an arrow key and a plain predicate, or rename it to a command listed in BOOL_COMMANDS
- Category: editor
- Added: 2026-11-19

### requires display_width, which it never names; also unused: carat/domain/last_change.rb:2 at carat/use_cases/visual/extend_visual.rb:6 (sprint-30 sweep quality, note 30)

- Location: carat/use_cases/visual/extend_visual.rb:6
- Why: requires display_width, which it never names; also unused: carat/domain/last_change.rb:2 position and :5 display_width, carat/use_cases/history/walk_history.rb:3 undo_tree, carat/use_cases/completion/show_completion.rb:4 completion_request, carat/use_cases/visual/reselect_visual.rb:4 selection, carat/use_cases/windows/toggle_slot.rb:2 slot, carat/use_cases/actions/completion_handler.rb:3 outcome; and carat/domain/operators.rb requires registers and selection only to reach RegisterEntry and Block
- Fix: drop the unused requires and require register_entry and block directly
- Also: carat/use_cases/visual/extend_visual.rb, carat/use_cases/history/walk_history.rb, carat/use_cases/completion/show_completion.rb, carat/use_cases/visual/reselect_visual.rb, carat/use_cases/windows/toggle_slot.rb, carat/use_cases/actions/completion_handler.rb, carat/domain/operators.rb
- Category: editor
- Added: 2026-11-23
