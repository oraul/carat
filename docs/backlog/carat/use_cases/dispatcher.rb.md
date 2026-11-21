# Backlog: carat/use_cases/dispatcher.rb

### The tab width fallback is copied in ten places

- Location: carat/use_cases/dispatcher.rb:112, arrange_view.rb:43, repeat_last.rb:104, insert_tab.rb:25, leave_insert.rb:69, adapters/frame_presenter.rb:216, domain/operators.rb:172, :251, :272, display_width.rb:57 (sprint-8 sweep, quality); queued in `editing-dedup-a`.
- Why: `tabstop > 0 ? tabstop : 8` repeats Options#tab_width (carat/domain/options.rb:131), on the per-key path too, and Options already keeps tabstop at 1 or more.
- Fix: call options.tab_width, passing the width into the domain helpers.
- Also: carat/domain/options.rb
- Category: editor
- Added: 2026-11-16

### Six sites recompute Options#tab_width

- Location: carat/use_cases/dispatcher.rb:112, leave_insert.rb:69, repeat_last.rb:104, arrange_view.rb:43, insert_tab.rb:25, carat/adapters/frame_presenter.rb:216 (sweep, quality, three notes).
- Why: each spells tabstop > 0 ? tabstop : 8, a copy of Options#tab_width (carat/domain/options.rb:131).
- Fix outline: call options.tab_width at each site.
- Also: carat/adapters/frame_presenter.rb, carat/domain/options.rb
- Category: editor
- Added: 2026-11-17

### Six sites re-implement tab_width and two clamp_col (sprint-14 sweep quality)

- Location: carat/use_cases/dispatcher.rb:112, repeat_last.rb:104, arrange_view.rb:43, insert_tab.rb:25, leave_insert.rb:69, carat/adapters/frame_presenter.rb:216; clamp at carat/use_cases/operate.rb:204 and repeat_last.rb:116.
- Why: each restates Options#tab_width or EditorState#clamp_col, so a change to either rule misses copies.
- Fix outline: call options.tab_width and state.clamp_col and delete the copies. Queued in `editing-dedup-a`.
- Also: carat/adapters/frame_presenter.rb, carat/use_cases/operate.rb
- Category: editor
- Added: 2026-11-17

### The tabstop fallback is copied beside Options#tab_width (sprint-16 sweep quality)

- Location: carat/use_cases/dispatcher.rb:112, repeat_last.rb:104, arrange_view.rb:47, insert_tab.rb:25, leave_insert.rb:69, carat/domain/operators.rb:172, :251, :272, carat/domain/display_width.rb:57; Options#tab_width at options.rb:131.
- Why: "tabstop > 0 ? tabstop : 8" is spelled in 9 places while the visual use cases already call tab_width, so the fallback can drift.
- Fix outline: call options.tab_width, or pass it in, at each site.
- Also: carat/domain/operators.rb, carat/domain/display_width.rb
- Category: editor
- Added: 2026-11-18

### The tab width and shift width fallbacks are hand-written at ten sites (sprint-18 sweep quality)
- Location: `carat/use_cases/dispatcher.rb:114`, `repeat_last.rb:104`, `leave_insert.rb:71`, `arrange_view.rb:47`, `insert_tab.rb:25`, `carat/adapters/frame_presenter.rb:218`, `carat/domain/operators.rb:172`, `:251`, `:272`, `carat/domain/display_width.rb:57`.
- Why it matters: `tabstop > 0 ? tabstop : 8` repeats `Options#tab_width` (`options.rb:135`), dead since tabstop is validated from 1.
- Fix outline: call `options.tab_width`, and pass one resolved shift width (an `Options#shift_width`) to Operators.
- Also: carat/adapters/frame_presenter.rb, carat/domain/operators.rb, carat/domain/display_width.rb
- Category: editor
- Added: 2026-11-18

### Duplicates Options#tab_width (sprint-20 sweep quality, dispatcher.rb:114)

- Location: `carat/use_cases/dispatcher.rb:114`
- Why: duplicates Options#tab_width (tabstop > 0 ? tabstop : 8), as do arrange_view.rb:50, insert_tab.rb:25, leave_insert.rb:71, repeat_last.rb:105, and adapters/frame_presenter.rb:236, and Options.width_problem already keeps tabstop at 1 or more, so the fallback is dead
- Fix: call state.options.tab_width at each site
- Merged: ### Tabstop > 0 ? tabstop (sprint-20 sweep quality, dispatcher.rb:114)
- Location: `carat/use_cases/dispatcher.rb:114`
- Why: tabstop > 0 ? tabstop : 8 repeats Options#tab_width (carat/domain/options.rb:135), as do repeat_last.rb:105, arrange_view.rb:50, insert_tab.rb:25, leave_insert.rb:71, operators.rb:172/251/272, and display_width.rb:57
- Fix: call state.options.tab_width (or pass it) at each site
- Also: carat/domain/options.rb
- Category: editor
- Added: 2026-11-19

### carat/use_cases/dispatcher.rb:114: duplication: re-derives the tab width as tabstop > 0 (sprint-22 sweep quality)

- Location: `carat/use_cases/dispatcher.rb:114`
- Why: duplication: re-derives the tab width as tabstop > 0 ? tabstop : 8, which Options#tab_width already answers; the same expression repeats in repeat_last.rb:105, arrange_view.rb:50, insert_tab.rb:25, leave_insert.rb:71, operators.rb:172/320/341, display_width.rb:57, frame_presenter.rb:236
- Fix: call state.options.tab_width (and a shift_width reader for the operators) at every site
- Also reported: sprint-22 sweep note 26 (leave_insert.rb:71, repeat_last.rb:105, operators.rb:340)
- Category: editor
- Added: 2026-11-20

### Six use cases restate Options#tab_width (sprint-24 sweep quality)

- Location: `carat/use_cases/dispatcher.rb:114`, `repeat_last.rb:105`, `arrange_view.rb:50`, `insert_tab.rb:25`, `leave_insert.rb:71`, `carat/adapters/frame_presenter.rb:241`
- Why: `tabstop > 0 ? tabstop : 8` repeats the rule `Options#tab_width` (`carat/domain/options.rb:157`) names.
- Fix: call `state.options.tab_width` in each.
- Also: carat/adapters/frame_presenter.rb, carat/domain/options.rb
- Category: editor
- Added: 2026-11-21
