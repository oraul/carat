## MODIFIED Requirements

### Requirement: Text groups meet WCAG AA contrast
In every shipped palette, drawn with the theme's background, every group that carries text SHALL have a contrast ratio of at least 4.5:1, and every decoration group (`NonText`, `EndOfBuffer`, `WinSeparator`, `FloatBorder`, `Whitespace`, `SignColumn`, and the file-icon groups) at least 3:1, at 24-bit colors and at the 256 colors written. `TabLineFill`, `PmenuSbar`, and `PmenuThumb`, which carry no text, are exempt; the indent guides follow their own requirement.

#### Scenario: Every palette passes
- **WHEN** the contrast of every group of `carat-dark`, `carat-light`, `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured
- **THEN** no text group is below 4.5:1 and no decoration group below 3:1

#### Scenario: Comments are readable
- **WHEN** the contrast of `carat-dark`'s Comment is measured
- **THEN** it is at least 4.5:1

### Requirement: Text on the cursor line stays readable
In every shipped palette, with either background, every text group drawn on the cursor line SHALL keep a contrast ratio of at least 4.5:1 and every decoration group at least 3:1, over `CursorLine`'s background unless the group has its own, at 24-bit colors and at the 256 colors written. There a group with the terminal's foreground SHALL take the palette's text color. `TabLineFill`, `PmenuSbar`, and `PmenuThumb`, which carry no text, are exempt; the indent guides follow their own requirement.

#### Scenario: Every palette passes on the cursor line
- **WHEN** the contrast of every group of the six shipped palettes is measured on the cursor line, with either background, at 24-bit colors and at 256 colors
- **THEN** no text group is below 4.5:1, no decoration group below 3:1, and no group keeps the terminal's foreground

#### Scenario: The cursor line on the terminal's background
- **WHEN** the background is `terminal` and a Normal cell is drawn on the cursor line
- **THEN** it has the palette's text color over `CursorLine`'s background, the colors it has on the line with the theme's background

## ADDED Requirements

### Requirement: The indent guides have colors of their own
Every palette SHALL color `IblIndent` and `IblScope` with two color roles of their own, apart from its text roles. In `carat-dark` they SHALL be #30364b and #46506e, and in `carat-light` #d8dce8 and #a9b4d6, both basic color 8 at 16 colors.

#### Scenario: The guide colors
- **WHEN** `carat-dark` and `carat-light` are drawn
- **THEN** `IblIndent` and `IblScope` are #30364b and #46506e on `carat-dark`, #d8dce8 and #a9b4d6 on `carat-light`, and basic color 8 at 16 colors

### Requirement: The indent guides recede behind the text
In `carat-dark` and `carat-light`, on the background and on the cursor line, at 24-bit colors and at the 256 colors written, `IblIndent`'s contrast SHALL be below `IblScope`'s, `IblScope`'s below `Comment`'s, and `IblIndent`'s at least 1.1:1, so a guide stays visible but never reads as text. In the other shipped palettes both guides SHALL keep the decorations' 3:1 there.

#### Scenario: The guides order below Comment
- **WHEN** the contrast of `IblIndent`, `IblScope`, and `Comment` of `carat-dark` and of `carat-light` is measured on the background and on the cursor line, at 24-bit colors and at 256 colors
- **THEN** `IblIndent` is below `IblScope`, `IblScope` is below `Comment`, and `IblIndent` is at least 1.1:1

#### Scenario: The other palettes' guides keep 3:1
- **WHEN** the contrast of `IblIndent` and `IblScope` of `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured on the background and on the cursor line, at 24-bit colors and at 256 colors
- **THEN** neither is below 3:1
