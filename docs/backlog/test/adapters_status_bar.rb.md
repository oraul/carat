# Backlog: test/adapters_status_bar.rb

### NO_COLOR and 16 colors are proven on the groups, not on the terminal bytes
- Location: `test/adapters_status_bar.rb`, `test/domain_theme.rb`, `carat/drivers/ansi_terminal.rb`
- Why: the tests assert the bar's cell groups under the presenter's plain mode and the group's 16-color and 256-color theme entries; no test writes the bar through the ANSI driver at 16 colors or with `NO_COLOR` to read the escape sequences, so a regression in how the driver maps `StatusLineDim` would not show.
- Fix: add a smoke case that draws the bar through the driver at 16 colors and under `NO_COLOR` and compares the written sequences for `StatusLine` and `StatusLineDim`.
- Also: test/domain_theme.rb, carat/drivers/ansi_terminal.rb
- Category: code-quality
- Added: 2026-11-22
