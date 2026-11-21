# Backlog: carat/use_cases/actions/tab_handler.rb

## tab-keys quality advisory at carat/use_cases/actions/tab_handler.rb:514

- Why: cleverness: the tabline flag is derived from the array position (tabline: i > 2), which breaks silently when a name is added or reordered.
- Fix: a parallel tablines array beside names and targets, or register the two tabline actions on their own lines.
- Category: editor
- Added: 2026-11-12

## Small code findings of the sprint-2 review and sweep at 8b9bf6a

- Where: `carat/use_cases/actions/tab_handler.rb:47` ties the tabline flag to a name's position (`i > 2`); `carat/domain/tab_list.rb:86` next_tab returns a bool no caller reads (a BOOL_COMMANDS entry kept for it); `carat/plugins/finder/plugin.rb:153` no_paths misnamed and the OPEN literal repeated at 79 and 87; `carat/use_cases/discovery/follow_palette.rb:103` trims the colon twice; `carat/domain/command_grammar.rb:139` accept and accept_visual share a start; `carat/domain/runs.rb:18` names a parameter cls; `carat/domain/buffer.rb:387` repeats initialize's empty line; `carat/domain/transaction.rb:297` merged? changes state; comments past the wrap in `carat/use_cases/handle_key.rb:65`, `carat/use_cases/discovery/show_key_hints.rb:23`, `carat/use_cases/completion/show_completion.rb:25`, `carat/use_cases/completion/show_completion_docs.rb:146`.
- Why it matters: copies, unclear names, and dead returns the naming and wrap rules forbid.
- Fix outline: a tablines array, a void next_tab, the renames, one private helper per copy, and the rewraps, each in its domain's batch.
- Also: carat/domain/tab_list.rb, carat/plugins/finder/plugin.rb, carat/use_cases/discovery/follow_palette.rb, carat/domain/command_grammar.rb, carat/domain/runs.rb, carat/domain/buffer.rb, carat/domain/transaction.rb, carat/use_cases/handle_key.rb, carat/use_cases/discovery/show_key_hints.rb, carat/use_cases/completion/show_completion.rb, carat/use_cases/completion/show_completion_docs.rb
- Category: editor
- Added: 2026-11-14
