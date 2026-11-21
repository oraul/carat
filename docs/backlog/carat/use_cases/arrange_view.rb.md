# Backlog: carat/use_cases/arrange_view.rb

## The view reserves its top rows twice

- Where: `carat/use_cases/arrange_view.rb:46` and 63 (`reserve_headers`, `reserve_winbars`). Periodic quality at ce6abdb; queue item `bars-tidy`.
- Why it matters: one give-the-first-row step written twice.
- Fix outline: one `Window` method both call.
- Category: editor
- Added: 2026-11-10

### The cursor's screen row is spelled in eight places

- Location: carat/use_cases/arrange_view.rb:108, :109, show_completion_docs.rb:92, :106, open_completion_popup.rb:75, carat/domain/layout.rb:247, show_signature.rb:66, show_hover.rb:77, open_definition_float.rb:32, frame_presenter.rb:735 (sweep, quality).
- Why: window.row + cursor.row - window.top is written out eight times, the column twice.
- Fix outline: Window#cursor_screen_row and a cursor_screen_col reader used by every site.
- Also: carat/domain/layout.rb
- Category: editor
- Added: 2026-11-17

### Cursor display column inside a closed fold drifts from the drawn one
- Location: carat/use_cases/arrange_view.rb:107
- Why: correctness; ArrangeView takes the cursor's display column from the line's column even inside a closed fold, while FramePresenter (carat/adapters/frame_presenter.rb:734) uses window.left there, so the scroll and the drawn cursor can disagree.
- Fix: one Window or presenter helper for the cursor's shown column, used by both.
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-17

### Visual modes do not take in closed folds
- Location: carat/use_cases/arrange_view.rb:138
- Why: correctness; as Neovim's foldAdjustVisual does not happen here, Vd on a closed fold over rows 0 and 1 deletes only row 0 and leaves a one-line fold, and carat/adapters/frame_presenter.rb:829 marks no selection on a fold row, while docs/compatibility.md says a linewise operator starting on a fold acts on all its lines.
- Fix: in a visual mode extend the anchor and cursor rows to the fold edges (first_row of the upper, last_row of the lower), paint the selection on the fold row, and add editor_folds rows such as zfjVd.
- Also: carat/adapters/frame_presenter.rb, docs/compatibility.md
- Category: editor
- Added: 2026-11-17

### Replace mode cannot be entered, so its fold opening has no test
- Location: carat/use_cases/arrange_view.rb (typing), carat/domain/mode.rb REPLACE
- Why: no key or handler enters Mode::REPLACE (R is unbound), so the replace branch that opens closed folds cannot be proved by a table row; the quality advisory asked for zfjRX<Esc>.
- Fix: when R is implemented, add the row zfjRX<Esc> expecting [[0, 1, false]] and the lines X b c d e.
- Also: carat/domain/mode.rb
- Category: editor
- Added: 2026-11-19

### Replace mode opening closed folds has no test row
- Location: carat/use_cases/arrange_view.rb:58
- Why: replace mode now opens the closed folds holding the cursor, but only insert mode has a test row; R is unbound in normal mode and Mode::REPLACE cannot be entered, so it cannot be tested yet (quality advisory, tests beside behavior).
- Fix: add the table row `zfjRX<Esc>` expecting [[0, 1, false]] and the lines `X b c d e` once R is implemented.
- Category: editor
- Added: 2026-11-19
