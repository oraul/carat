## ADDED Requirements

### Requirement: The selected tab reads at a glance
In every shipped palette `TabLineSel`, the group of the selected buffer tab, the current tab-page number, and the current window's winbar, SHALL be drawn bold at every color depth in the palette's color for text on a strong accent over its blue accent, its background at 3:1 or more against the backgrounds of `TabLine` and `TabLineFill` at 24-bit and 256 colors and another basic color than theirs at 16 colors; `TabLine` SHALL not be bold, so the selected tab is never told by color alone.

#### Scenario: Every palette's selected tab stands out
- **WHEN** the tab groups of `one_dark`, `one_light`, `dark_plus`, and `light_plus` are measured, with the theme's background or the terminal's
- **THEN** `TabLineSel`'s background is at 3:1 or more from `TabLine`'s and `TabLineFill`'s at 24 bits and 256 colors, differs from theirs at 16 colors, and `TabLineSel` is bold at every depth while `TabLine` is not
