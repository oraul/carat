# Backlog: carat/use_cases/leave_insert.rb

## Eleven copies inline the tab width Options already answers

- Where: at the `pinned-main` change, `carat/use_cases/leave_insert.rb:69`, `carat/use_cases/insert_tab.rb:22`, `carat/use_cases/repeat_last.rb:104`, `carat/use_cases/arrange_view.rb:40`, `carat/use_cases/dispatcher.rb:112`, `carat/use_cases/visual/extend_visual.rb:54`, and `carat/adapters/frame_presenter.rb:178` (periodic quality at b0dd342, 5722559, cd87445, and b76b722), and in the domain `carat/domain/operators.rb:172`, `251`, and `272` and `carat/domain/display_width.rb:62` (pinned-main advisory, at 847851d).
- Why it matters: `tabstop > 0 ? tabstop : 8` is copied eleven times beside `Options#tab_width` (`carat/domain/options.rb:92` at 847851d), so a rule change misses copies.
- Fix outline: call `options.tab_width` in the eleven places (the domain ones through one shared domain function where no `Options` is at hand) and drop the inline copies.
- Also: carat/use_cases/insert_tab.rb, carat/use_cases/repeat_last.rb, carat/use_cases/arrange_view.rb, carat/use_cases/dispatcher.rb, carat/use_cases/visual/extend_visual.rb, carat/adapters/frame_presenter.rb, carat/domain/operators.rb, carat/domain/display_width.rb, carat/domain/options.rb
- Category: editor
- Added: 2026-11-09

### duplication: tabstop > 0 ? tabstop : 8 is at carat/use_cases/leave_insert.rb:71 (sprint-26 sweep quality, note 23)

- Location: carat/use_cases/leave_insert.rb:71
- Why: duplication: tabstop > 0 ? tabstop : 8 is re-implemented here and in carat/use_cases/repeat_last.rb:105, carat/use_cases/insert_tab.rb:25, carat/use_cases/arrange_view.rb:50 (also dispatcher.rb:114, frame_presenter.rb:243) though Options#tab_width holds the rule
- Fix: use state.options.tab_width everywhere
- Also: carat/use_cases/repeat_last.rb, carat/use_cases/insert_tab.rb, carat/use_cases/arrange_view.rb
- Category: editor
- Added: 2026-11-22

### duplication: re-inlines the tabstop fallback (tabstop > 0 ? tabstop at carat/use_cases/leave_insert.rb:71 (sprint-32 sweep quality, note 24)
- Location: carat/use_cases/leave_insert.rb:71
- Why: duplication: re-inlines the tabstop fallback (tabstop > 0 ? tabstop : 8) that Options#tab_width (carat/domain/options.rb:173) already provides, as do repeat_last.rb:105, arrange_view.rb:50, insert_tab.rb:25 (and dispatcher.rb:114)
- Fix: call state.options.tab_width at each site
- Category: quality
