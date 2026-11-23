## MODIFIED Requirements

### Requirement: The selected tab reads at a glance
In every shipped palette `TabLineSel`, the group of the selected buffer tab, SHALL be drawn bold at every attribute depth in Normal's own foreground and background, so the selected tab takes the editor's background with no accent fill; `TabLineName`, the group of the current tab-page number, the current window's winbar name, and the shown view of a slot header, SHALL be drawn bold over the tab row's own background; `TabLine` SHALL not be bold, so the selected tab is never told by color alone.

#### Scenario: The selected tab is bold on the editor's background
- **WHEN** the tab groups of the six shipped palettes are measured, with the theme's background or the terminal's, and the sequences of carat-dark at 24 bits, 256 colors, and 16 colors are read
- **THEN** `TabLineSel` and `TabLineName` are bold and `TabLine` is not, `TabLineSel` has Normal's colors, and the sequence of `TabLineSel` has no accent background and is Normal's with the bold added at every depth
