## MODIFIED Requirements

### Requirement: Text groups meet WCAG AA contrast
In every shipped palette, drawn with the theme's background, every group that carries text SHALL have a contrast ratio of at least 4.5:1, and every decoration group (`NonText`, `EndOfBuffer`, `WinSeparator`, `FloatBorder`, `Whitespace`, `SignColumn`, the file-icon groups) at least 3:1, at 24-bit colors and the 256 written. `TabLineFill`, `PmenuSbar`, and `PmenuThumb` are exempt; the guides, Carat's `Whitespace`, Carat's `WinSeparator`, and float borders have their own rules.

#### Scenario: Every palette passes
- **WHEN** the contrast of every group of `carat-dark`, `carat-light`, `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured
- **THEN** no text group is below 4.5:1 and no decoration group below 3:1

#### Scenario: Comments are readable
- **WHEN** the contrast of `carat-dark`'s Comment is measured
- **THEN** it is at least 4.5:1

### Requirement: Text on the cursor line stays readable
In every shipped palette, with either background, every text group on the cursor line SHALL keep 4.5:1 and every decoration group 3:1, over `CursorLine`'s background unless it has its own, at 24 bits and at the 256 colors written; a group with the terminal's foreground SHALL take the palette's text color there. `TabLineFill`, `PmenuSbar`, and `PmenuThumb` are exempt; the guides, Carat's `WinSeparator`, and Carat's float borders have their own rules.

#### Scenario: Every palette passes on the cursor line
- **WHEN** the contrast of every group of the six shipped palettes is measured on the cursor line, with either background, at 24-bit colors and at 256 colors
- **THEN** no text group is below 4.5:1, no decoration group below 3:1, and no group keeps the terminal's foreground

#### Scenario: The cursor line on the terminal's background
- **WHEN** the background is `terminal` and a Normal cell is drawn on the cursor line
- **THEN** it has the palette's text color over `CursorLine`'s background, the colors it has on the line with the theme's background

## ADDED Requirements

### Requirement: A sidebar window sits on a darker background
Every group SHALL have a sidebar id, its id plus `Highlight::SIDEBAR_LAYER`, which keeps the group's foreground and attributes and takes `PANEL_NC` as its background unless the group has one of its own; a group with the terminal's foreground SHALL take the palette's text color there. At 16 colors the sidebar id SHALL equal the group. Text groups there SHALL keep 4.5:1 and decorations 3:1, in every palette, at 24 bits and at 256 colors.

#### Scenario: A sidebar window sits on a darker background
- **WHEN** a group is looked up on the sidebar layer in the six palettes, with the theme's background and with the terminal's
- **THEN** its foreground and attributes are the group's, its background `PanelNC`'s unless it has its own, at 16 colors it equals the group, `Highlight.base` strips the layer, and no group is below the contrast rules

### Requirement: WinSeparator is the quiet border tone
Every palette SHALL color `WinSeparator` with its `BORDER` role, basic color 8 at 16 colors, no background. In `carat-dark` and `carat-light` it SHALL stay at least 1.5:1 from the editor's background at 24-bit colors and 1.4:1 at the 256 colors written, out of the 3:1 floor, so a line between two windows of one color reads as a quiet edge; the other palettes' separators SHALL keep the decorations' 3:1.

#### Scenario: WinSeparator is the quiet border tone
- **WHEN** `WinSeparator` is looked up in the six palettes and its contrast on `Normal`'s background is measured for `carat-dark` and `carat-light`
- **THEN** it is the palette's `BORDER` color and basic color at 16 colors, and at least 1.5:1 at 24 bits and 1.4:1 at 256 colors
