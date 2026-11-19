### Replace mode cannot be entered, so its fold opening has no test
- Location: carat/use_cases/arrange_view.rb (typing), carat/domain/mode.rb REPLACE
- Why: no key or handler enters Mode::REPLACE (R is unbound), so the replace branch that opens closed folds cannot be proved by a table row; the quality advisory asked for zfjRX<Esc>.
- Fix: when R is implemented, add the row zfjRX<Esc> expecting [[0, 1, false]] and the lines X b c d e.
### Extra push allowed by push --pr-text without a blocked text review
- Location: tools/run_state.sh:1327
- Why: `push --pr-text` only checks that the recorded push differs from HEAD, and agent_guard.sh lets the contributor pass `--pr-text` at any time, so a contributor gets one more push per run even when no pull request text review blocked, loosening the push-count rule. The merge gates still run on every head, so no unreviewed code reaches main. This came in with the merge of main (#224), not with this change's commit. Security Low, confidence 4.
- Fix: Have the workflow write a run-state marker (for example `pr_text_blocked`) when the text review blocks, make `push --pr-text` refuse unless it is set, clear it after the push, and add expect cases in tools/tools_test.sh.

### Replace mode opening closed folds has no test row
- Location: carat/use_cases/arrange_view.rb:58
- Why: replace mode now opens the closed folds holding the cursor, but only insert mode has a test row; R is unbound in normal mode and Mode::REPLACE cannot be entered, so it cannot be tested yet (quality advisory, tests beside behavior).
- Fix: add the table row `zfjRX<Esc>` expecting [[0, 1, false]] and the lines `X b c d e` once R is implemented.

### close_tab walks the tab page's slots twice
- Location: carat/domain/buffer_list.rb:408
- Why: close_tab collects the kept view windows' buffers (lines 407-412) and again walks the slots in drop_slot_folds (line 413), a duplication (quality advisory).
- Fix: drop each kept view window's folds in the existing loop and call drop_slot_folds only from close_window.

### Slot#clear forgets a kept hidden view window without dropping its folds
- Location: carat/domain/slot.rb:102
- Why: Slot#clear, also run by attach, forgets a kept hidden view window without drop_folds, so a plugin closing or replacing a hidden side window leaves its fold list tracked by the buffer (spec currency: windows, closing a window drops its folds; quality advisory).
- Fix: drop the kept window's folds before clear forgets it (in BufferList or the caller), with a test like the :tabclose slot assertion.
