# Backlog: test/editor_tab_flows.rb

### No flow covers a buffer switch from a pinned documentation split
- Location: test/editor_tab_flows.rb:189
- Why: the design states a behavior change for a PinHover split, which now switches itself instead of the file window, yet only the reading view has flows, so a regression of the pinned split would pass.
- Fix: add one flow row that pins a hover split and runs :bn there, expecting the split to switch and the file window to keep its buffer.
- Category: code-quality
- Added: 2026-11-17

### tab_boundary? takes a digit after a gem as a tab boundary
- Location: test/editor_tab_flows.rb:147
- Why: tab_boundary? accepts a digit after a gem as well as after a space, so a separator before a name such as "*1.txt" is now dropped, while the comment says only a trailing counter " N> " (space then digit) is meant.
- Fix: accept the digit only when chars[i] == " ".
- Category: code-quality
- Added: 2026-11-21

### Tab-flow tests guess gems and separators with about 60 lines of heuristics (sprint-24 review quality)

- Location: `test/editor_tab_flows.rb:105`
- Why: strip_tab_cells, counter_end, and tab_boundary? guess which painted cells are gems or separators so old rows still match, and need tests of their own.
- Fix: assert the names and the tab count directly, or update the expected rows to the painted text.
- Category: code-quality
- Added: 2026-11-21
