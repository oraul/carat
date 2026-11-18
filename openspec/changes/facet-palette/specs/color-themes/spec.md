## MODIFIED Requirements

### Requirement: Text groups meet WCAG AA contrast
In every shipped palette, drawn with the theme's background, every group that carries text SHALL have a contrast ratio of at least 4.5:1, and every decoration group (`NonText`, `EndOfBuffer`, `WinSeparator`, `FloatBorder`, `Whitespace`, `SignColumn`, and the file-icon groups) at least 3:1, at 24-bit colors and at the 256 colors written. `TabLineFill`, `PmenuSbar`, and `PmenuThumb`, which carry no text, are exempt; the guides and Carat's float borders have their own rules.

#### Scenario: Every palette passes
- **WHEN** the contrast of every group of `carat-dark`, `carat-light`, `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured
- **THEN** no text group is below 4.5:1 and no decoration group below 3:1

#### Scenario: Comments are readable
- **WHEN** the contrast of `carat-dark`'s Comment is measured
- **THEN** it is at least 4.5:1

### Requirement: Text on the cursor line stays readable
In every shipped palette, with either background, every text group drawn on the cursor line SHALL keep a contrast ratio of at least 4.5:1 and every decoration group at least 3:1, over `CursorLine`'s background unless it has its own, at 24-bit colors and at the 256 colors written. There a group with the terminal's foreground SHALL take the palette's text color. `TabLineFill`, `PmenuSbar`, and `PmenuThumb` carry no text and are exempt; the guides and Carat's float borders have their own rules.

#### Scenario: Every palette passes on the cursor line
- **WHEN** the contrast of every group of the six shipped palettes is measured on the cursor line, with either background, at 24-bit colors and at 256 colors
- **THEN** no text group is below 4.5:1, no decoration group below 3:1, and no group keeps the terminal's foreground

#### Scenario: The cursor line on the terminal's background
- **WHEN** the background is `terminal` and a Normal cell is drawn on the cursor line
- **THEN** it has the palette's text color over `CursorLine`'s background, the colors it has on the line with the theme's background

### Requirement: The mode pills read on their accents
In every shipped palette the mode pills SHALL be drawn bold in the palette's color for text on a strong accent over the mode's accent: blue for normal, green for insert, purple for visual, red for replace, and cyan for the command line and every query picker's prompt, at 4.5:1 or more at 24-bit and 256 colors.

#### Scenario: Every palette's pills pass
- **WHEN** the contrast of the five pill groups of the six shipped palettes is measured
- **THEN** none is below 4.5:1

#### Scenario: The command pill is cyan
- **WHEN** the command line or a query picker's prompt is open in any shipped palette
- **THEN** the pill is drawn in `StatusLineModeCommand`, the palette's text on a strong accent over its cyan, bold

## ADDED Requirements

### Requirement: The float border has a color of its own
Every palette SHALL color `FloatBorder` with a border role of its own, apart from its text roles: #3b4157 in `carat-dark` and #c9cdd9 in `carat-light`, basic color 8 at 16 colors. In `carat-dark` and `carat-light` the float border SHALL stay at least 1.3:1 from the float's background, on its own and on the cursor line, at 24-bit colors and at the 256 colors written, so it frames the float without reading as text; the other palettes' borders SHALL keep the decorations' 3:1.

#### Scenario: The border colors
- **WHEN** `carat-dark` and `carat-light` are drawn
- **THEN** `FloatBorder` is #3b4157 on `carat-dark` and #c9cdd9 on `carat-light`, basic color 8 at 16 colors

#### Scenario: The border stays apart from the float
- **WHEN** the contrast of `FloatBorder` of `carat-dark` and of `carat-light` is measured on the float's background, at 24-bit colors and at 256 colors
- **THEN** it is at least 1.3:1

### Requirement: Carat's palettes draw search on a soft tint
`carat-dark` and `carat-light` SHALL draw `Search` and `Todo` on a soft search tint, #4a4129 and #f7e3a1, in a text color of its own, #c8ccd8 and #2f3340, black at 16 colors, and `CurSearch` in the strong INC_SEARCH color, bold.

#### Scenario: The search colors
- **WHEN** `carat-dark` and `carat-light` are drawn
- **THEN** `Search` is #c8ccd8 on #4a4129 and #2f3340 on #f7e3a1, black on bright yellow at 16 colors, and `CurSearch` has INC_SEARCH's background and is bold

### Requirement: Carat's palettes give the selection and the panels their Facet colors
`carat-light`'s selection SHALL be #c5cff0, at least 1.5:1 from its background, and its panel surfaces #eceef3. Each palette SHALL hold a dim text color for the status bar, #a4aabd and #5c6173 in Carat's, at least 4.5:1 on the bar. At 256 colors `carat-dark`'s panel surfaces SHALL be index 233, apart from the background's 234.

#### Scenario: The light selection shows
- **WHEN** `carat-light`'s `Visual` is drawn
- **THEN** its background is #c5cff0, above 1.26:1 and at least 1.5:1 from the background

#### Scenario: The panel colors
- **WHEN** `carat-dark` and `carat-light` are drawn
- **THEN** the status bar's dim text color is #a4aabd and #5c6173, at least 4.5:1 on the bar, `carat-light`'s `TabLine` and `NormalFloat` backgrounds are #eceef3, and `carat-dark`'s `TabLine` background is index 233 at 256 colors while `Normal`'s is 234
