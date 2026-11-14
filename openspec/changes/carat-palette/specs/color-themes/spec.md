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
- **WHEN** a configuration line is "option.theme carat-light", a name that was once an alias of `one_light`
- **THEN** the colors are those of Carat's own `carat-light`, which differ from `one_light`'s

#### Scenario: Unknown theme
- **WHEN** the project file's first line is "option.theme solarized"
- **THEN** ".caratrc:1: unknown theme solarized" is reported and the colors are those of `carat-dark`

### Requirement: Text groups meet WCAG AA contrast
In every shipped palette, drawn with the theme's background, every group that carries text SHALL have a contrast ratio of at least 4.5:1 between its foreground and background, and every decoration group (`NonText`, `EndOfBuffer`, `WinSeparator`, `FloatBorder`, `Whitespace`, `SignColumn`, `IblIndent`, `IblScope`, and the file-icon groups) at least 3:1, both at 24-bit colors and at the 256 colors written for them. `TabLineFill`, `PmenuSbar`, and `PmenuThumb`, which carry no text, are exempt.

#### Scenario: Every palette passes
- **WHEN** the contrast of every group of `carat-dark`, `carat-light`, `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured
- **THEN** no text group is below 4.5:1 and no decoration group below 3:1

#### Scenario: Comments are readable
- **WHEN** the contrast of `carat-dark`'s Comment is measured
- **THEN** it is at least 4.5:1

### Requirement: Text on the cursor line stays readable
In every shipped palette, drawn with the theme's background, every group that carries text SHALL keep a contrast ratio of at least 4.5:1 between its foreground and its background when drawn on the cursor line, and every decoration group at least 3:1, on the `CursorLine` background unless the group has a background of its own, at 24-bit colors and at the 256 colors written for them. `TabLineFill`, `PmenuSbar`, and `PmenuThumb`, which carry no text, are exempt.

#### Scenario: Every palette passes on the cursor line
- **WHEN** the contrast of every group of the six shipped palettes is measured on the cursor line
- **THEN** no text group is below 4.5:1 and no decoration group below 3:1

### Requirement: The mode pills read on their accents
In every shipped palette the mode pills SHALL be drawn bold in the palette's color for text on a strong accent over the mode's accent: blue for normal, green for insert, purple for visual, red for replace, and yellow for command-line, at 4.5:1 or more at 24-bit and 256 colors.

#### Scenario: Every palette's pills pass
- **WHEN** the contrast of the five pill groups of the six shipped palettes is measured
- **THEN** none is below 4.5:1

### Requirement: The lsp slot reads on the editor's background
In every shipped palette the `lsp` groups SHALL be drawn in the accent of their state over the editor's background, as the diagnostic groups are: starting yellow, ready green, and error red and bold, at 4.5:1 or more at 24-bit and 256 colors.

#### Scenario: Every palette's lsp groups pass
- **WHEN** the contrast of the three `lsp` groups of the six shipped palettes is measured
- **THEN** none is below 4.5:1

### Requirement: Groups in a float stay readable over its background
A syntax or markup group drawn inside a float SHALL keep its foreground and attributes and take NormalFloat's background unless it has a background of its own. In every shipped palette, drawn with the theme's background, every syntax and markup group that carries text SHALL have a contrast of at least 4.5:1 over that background, at 24-bit colors and at the 256 colors written for them.

#### Scenario: Every palette passes in a float
- **WHEN** the contrast of every syntax and markup group of the six shipped palettes is measured over the float background
- **THEN** none is below 4.5:1

### Requirement: The selected tab reads at a glance
In every shipped palette `TabLineSel`, the group of the selected buffer tab, the current tab-page number, and the current window's winbar, SHALL be drawn bold at every color depth in the palette's color for text on a strong accent over its blue accent, its background at 3:1 or more against the backgrounds of `TabLine` and `TabLineFill` at 24-bit and 256 colors and another basic color than theirs at 16 colors; `TabLine` SHALL not be bold, so the selected tab is never told by color alone.

#### Scenario: Every palette's selected tab stands out
- **WHEN** the tab groups of the six shipped palettes are measured, with the theme's background or the terminal's
- **THEN** `TabLineSel`'s background is at 3:1 or more from `TabLine`'s and `TabLineFill`'s at 24 bits and 256 colors, differs from theirs at 16 colors, and `TabLineSel` is bold at every depth while `TabLine` is not
