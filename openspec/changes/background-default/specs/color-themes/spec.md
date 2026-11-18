## REMOVED Requirements

### Requirement: The background option chooses who paints the background
**Reason**: Its scenario "Transparent by default" no longer describes the editor: the shipped configuration paints the palette's background.
**Migration**: The behavior continues under the requirement "The background option paints the theme by default", which keeps the terminal's background for a configuration line naming it.

## ADDED Requirements

### Requirement: The background option paints the theme by default
The `option.background` line SHALL take `theme`, the default, or `terminal`. With `theme` every cell, the cleared screen included, SHALL be drawn on the palette's background; with `terminal` `Normal` and every group without a background of its own SHALL keep the terminal's colors. A background or theme a configuration line names SHALL be kept. Any other value SHALL be reported as `file:line: unknown background VALUE` and keep the value before it.

#### Scenario: The background is painted by default
- **WHEN** the editor starts with the shipped configuration and a frame is first written at 256 colors
- **THEN** the screen is cleared after `\e[0;38;5;252;48;5;234m`, carat-dark's text color and background, and a Normal cell is preceded by the same sequence

#### Scenario: A named background is kept
- **WHEN** a configuration line is "option.background terminal" and a frame is first written
- **THEN** a Normal cell is preceded by `\e[0m` and the screen is not cleared on the palette's background

#### Scenario: A named theme is kept
- **WHEN** a configuration line is "option.theme carat-light" and a frame is first written at 256 colors
- **THEN** the screen is cleared after carat-light's Normal sequence and a Normal cell is preceded by the same sequence

#### Scenario: The theme paints
- **WHEN** a configuration line is "option.background theme", the theme is `one_dark`, and a frame is first written at 256 colors
- **THEN** the screen is cleared after `\e[0;38;5;249;48;5;236m`, the palette's text color and background, and a Normal cell is preceded by the same sequence

#### Scenario: Scrolled-in rows are painted
- **WHEN** the background is `theme` and a window scrolls by a line
- **THEN** the scroll region is sent after the Normal sequence, so the row that came into view is cleared on the palette's background

#### Scenario: Unknown value
- **WHEN** the project file's first line is "option.background dark"
- **THEN** ".caratrc:1: unknown background dark" is reported and the background stays `theme`
