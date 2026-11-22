# Backlog: carat/use_cases/repeat_last.rb

### And carat/use_cases/repeat_last.rb (sprint-20 sweep quality, operate.rb:233)

- Location: `carat/use_cases/operate.rb:233`
- Why: and carat/use_cases/repeat_last.rb:117 duplication: each private clamp(state, row, col) restates EditorState#clamp_col (carat/domain/editor_state.rb:100)
- Fix: delete both helpers and call state.clamp_col(row, col), as PutOverSelection and GlobalCommand already do
- Also: carat/use_cases/operate.rb, carat/domain/editor_state.rb
- Category: editor
- Added: 2026-11-19

### Duplication (sprint-20 sweep quality, repeat_last.rb:116)

- Location: `carat/use_cases/repeat_last.rb:116`
- Why: duplication: the private clamp repeats EditorState#clamp_col (editor_state.rb:100) line for line
- Fix: call state.clamp_col(row, col) at :102, :107, :112 and drop clamp
- Category: editor
- Added: 2026-11-19

### Duplication (sprint-20 sweep quality, repeat_last.rb:105)

- Location: `carat/use_cases/repeat_last.rb:105`
- Why: duplication: re-derives the tab width (tabstop > 0 ? tabstop : 8) although Options#tab_width exists (options.rb:135), as do dispatcher.rb:114, leave_insert.rb:71, arrange_view.rb:50, insert_tab.rb:25
- Fix: use state.options.tab_width in each
- Merged: ### Carat/use_cases/arrange_view.rb (sprint-20 sweep quality, repeat_last.rb:105,)
- Location: `carat/use_cases/repeat_last.rb:105,`
- Why: carat/use_cases/arrange_view.rb:50, carat/use_cases/leave_insert.rb:71, carat/use_cases/insert_tab.rb:25, carat/use_cases/dispatcher.rb:114 duplication: each restates the fallback 'tabstop > 0 ? tabstop : 8', which Options#tab_width (carat/domain/options.rb:135) already provides and PutOverSelection uses
- Fix: replace each with options.tab_width
- Also: carat/use_cases/arrange_view.rb, carat/use_cases/leave_insert.rb, carat/use_cases/insert_tab.rb, carat/use_cases/dispatcher.rb, carat/domain/options.rb
- Category: editor
- Added: 2026-11-19

### robustness: last.replaying = true is reset only on the at carat/use_cases/repeat_last.rb:49 (sprint-26 sweep quality, note 27)

- Location: carat/use_cases/repeat_last.rb:49
- Why: robustness: last.replaying = true is reset only on the normal path (56), so a handler that raises leaves LastChange replaying and later changes unrecorded for the dot command
- Fix: wrap the handler call and the insert replay in begin/ensure last.replaying = false
- Category: editor
- Added: 2026-11-22
