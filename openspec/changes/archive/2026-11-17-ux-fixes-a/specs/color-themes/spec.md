## ADDED Requirements

### Requirement: The lsp slot reads on the status bar's background
In every shipped palette the `lsp` groups SHALL be drawn over the status bar's own background, the background of `StatusLine`, at 24-bit, 256, and 16 colors, so the bar shows as one band, each in the accent of its state picked for that bar: starting yellow, ready green, and error red and bold, at 4.5:1 or more on the bar at 24-bit and 256 colors.

#### Scenario: The lsp groups share the bar's background
- **WHEN** the backgrounds of the three `lsp` groups and of `StatusLine` of the six shipped palettes are read, with the terminal's background and with the theme's, at every color depth
- **THEN** each `lsp` group's background equals the `StatusLine` background

#### Scenario: Every palette's lsp groups pass on the bar
- **WHEN** the contrast of the three `lsp` groups of the six shipped palettes is measured on their own background
- **THEN** none is below 4.5:1 at 24-bit or at 256 colors

## REMOVED Requirements

### Requirement: The lsp slot reads on the editor's background
**Reason**: drawn on the terminal's or the editor's background, the slot left a hole in the status bar's band (ux-pass finding 3).
**Migration**: none; the groups keep their names and their state accents, now on the bar's background (requirement "The lsp slot reads on the status bar's background").
