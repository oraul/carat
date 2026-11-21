# Backlog: test/editor_tab_flows.rb

### No flow covers a buffer switch from a pinned documentation split
- Location: test/editor_tab_flows.rb:189
- Why: the design states a behavior change for a PinHover split, which now switches itself instead of the file window, yet only the reading view has flows, so a regression of the pinned split would pass.
- Fix: add one flow row that pins a hover split and runs :bn there, expecting the split to switch and the file window to keep its buffer.
- Category: code-quality
- Added: 2026-11-17

### The tab-flow row blanks every separator character, a name with a pipe would lose it
- Location: test/editor_tab_flows.rb, blank_separators
- Why: row 0 of a tab row has its `|` and `│` blanked to compare names, so a file named with a pipe would read differently; no flow names one.
- Fix: read the tab names from the buffer list and compare them with the row cells by column from the tab widths, or add a flow with such a name once the helper reads columns.
- Category: code-quality
- Added: 2026-11-21
