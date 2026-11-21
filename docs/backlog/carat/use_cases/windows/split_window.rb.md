# Backlog: carat/use_cases/windows/split_window.rb

## A refused split leaves the focused float

- Where: `SplitWindow` in `carat/use_cases/windows/split_window.rb` line 32, and `open_in_split`, which restores `tab.current` but not the float focus, at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: a split refused with E36 has already called `tab.floats.leave`, so the user loses the float's focus although nothing changed.
- Fix outline: read `tab.layout_window` for the gutter width and call `tab.floats.leave` only after the split succeeds, with a test row for E36 from a float.
- Category: editor
- Added: 2026-11-07

### SplitWindow takes five positional values (sprint-16 sweep quality)

- Location: carat/use_cases/windows/split_window.rb:31; callers window_handler.rb:44, pin_hover.rb:52, window_requests.rb:189.
- Why: two bare booleans among five values break area 11's rule that variants with a count go through a Data request, as FocusWindow, ScrollWindow, and SwitchTab do.
- Fix outline: a SplitRequest Data value (vertical, size, path, fresh) passed at the call sites.
- Category: editor
- Added: 2026-11-18

### carat/use_cases/windows/split_window.rb:31: call(state, vertical, size, path, fresh) takes five positional variant (sprint-22 sweep quality)

- Location: `carat/use_cases/windows/split_window.rb:31`
- Why: call(state, vertical, size, path, fresh) takes five positional variant values, a row count among them, where area 11's rule (docs/codebase-map.md:403) wants a Data request for variants carrying a count, as FocusRequest, ScrollRequest, and TabRequest do
- Fix: a SplitRequest value (vertical, size, path, fresh) passed to call
- Also: docs/codebase-map.md
- Category: editor
- Added: 2026-11-20
