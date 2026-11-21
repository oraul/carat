# Backlog: carat/use_cases/windows/open_tab.rb

## OpenTab copies a focused float's jumps and leaves it focused

- Where: `carat/use_cases/windows/open_tab.rb:31` (`state.window` is the focused float), unlike `SplitWindow`. Periodic quality at bd86828.
- Why it matters: the new tab page starts with a float's jump list and the float stays focused.
- Fix outline: leave the float first or copy from the layout window, with a row. Queue item `definition-tab`.
- Category: editor
- Added: 2026-11-11

## :tabnew from a float copies the float's jump list

- Where: `carat/use_cases/windows/open_tab.rb:220` copies `state.window.jumps`. Periodic quality advisory at d0d783c.
- Why it matters: while a float has the focus that list is empty, so the new tab page loses the layout window's jumps.
- Fix outline: copy the layout window's jumps, with a `test/editor_jumps.rb` row opening a tab from an entered float. Queue item `definitions-tidy`.
- Also: test/editor_jumps.rb
- Category: editor
- Added: 2026-11-11
