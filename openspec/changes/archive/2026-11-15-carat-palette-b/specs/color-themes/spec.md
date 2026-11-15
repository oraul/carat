## MODIFIED Requirements

### Requirement: The theme option selects a shipped theme
The `option.theme` line of the configuration SHALL select the palette: Carat's own `carat-dark` (the default) and `carat-light`, or `one_dark`, `one_light`, `dark_plus`, or `light_plus`; an unknown name SHALL be reported as `file:line: unknown theme NAME` and keep the theme set before it.

#### Scenario: Default theme
- **WHEN** the editor starts with the shipped configuration
- **THEN** the colors are those of `carat-dark`

#### Scenario: Light theme
- **WHEN** a configuration line is "option.theme light_plus"
- **THEN** the Comment group is written with `light_plus`'s comment color

#### Scenario: Alias
- **WHEN** a configuration line is "option.theme carat-light"
- **THEN** the colors are those of Carat's own `carat-light`, which is no alias: its colors differ from `one_light`'s

#### Scenario: Unknown theme
- **WHEN** the project file's first line is "option.theme solarized"
- **THEN** ".caratrc:1: unknown theme solarized" is reported and the colors are those of `carat-dark`

### Requirement: Text on the cursor line stays readable
In every shipped palette, with either background, every text group drawn on the cursor line SHALL keep a contrast ratio of at least 4.5:1 and every decoration group at least 3:1, over `CursorLine`'s background unless the group has its own, at 24-bit colors and at the 256 colors written. There a group with the terminal's foreground SHALL take the palette's text color. `TabLineFill`, `PmenuSbar`, and `PmenuThumb`, which carry no text, are exempt.

#### Scenario: Every palette passes on the cursor line
- **WHEN** the contrast of every group of the six shipped palettes is measured on the cursor line, with either background, at 24-bit colors and at 256 colors
- **THEN** no text group is below 4.5:1, no decoration group below 3:1, and no group keeps the terminal's foreground

#### Scenario: The cursor line on the terminal's background
- **WHEN** the background is `terminal` and a Normal cell is drawn on the cursor line
- **THEN** it has the palette's text color over `CursorLine`'s background, the colors it has on the line with the theme's background
