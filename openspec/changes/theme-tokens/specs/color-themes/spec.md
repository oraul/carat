## MODIFIED Requirements

### Requirement: The editor's own highlights are groups too
The editor SHALL know 41 UI groups by Neovim's names: `Normal`, `LineNr`, `StatusLine`, `ErrorMsg`, `NonText`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `SignColumn`, `Search`, `IncSearch`, `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `MoreMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, and `DiagnosticHint`. It SHALL draw its own parts in them, which every palette colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: A plugin asks for an editor group
- **WHEN** a plugin asks for the group `StatusLine`
- **THEN** the request fails with `No highlight group named StatusLine`

#### Scenario: The search groups have colors
- **WHEN** any shipped palette is chosen
- **THEN** `Search`, `IncSearch`, and `CurSearch` have a background color at 24-bit, 256, and 16 colors

#### Scenario: Every UI group has a color in every palette
- **WHEN** any shipped palette is chosen with the theme's background
- **THEN** every UI group has a 24-bit foreground and background

### Requirement: The theme option selects a shipped theme
The `option.theme` line of the configuration SHALL select the palette: `one_dark` (the default), `one_light`, `dark_plus`, or `light_plus`, with `carat-dark` and `carat-light` accepted as aliases of `one_dark` and `one_light`; an unknown name SHALL be reported as `file:line: unknown theme NAME` and keep the theme set before it. Each palette SHALL give the syntax groups its own colors. A theme gives every group a foreground and a background (or the terminal's own) and any of bold, italic, underline, and reverse.

#### Scenario: Default theme
- **WHEN** the editor starts with the shipped configuration
- **THEN** the colors are those of `one_dark`

#### Scenario: Light theme
- **WHEN** a configuration line is "option.theme light_plus"
- **THEN** the Comment group is written with `light_plus`'s comment color

#### Scenario: Alias
- **WHEN** a configuration line is "option.theme carat-light"
- **THEN** the colors are those of `one_light`

#### Scenario: Palettes differ in their syntax colors
- **WHEN** a Keyword cell is written with `one_dark` and with `dark_plus`
- **THEN** the two foregrounds differ

#### Scenario: Unknown theme
- **WHEN** the project file's first line is "option.theme solarized"
- **THEN** ".caratrc:1: unknown theme solarized" is reported and the colors are those of `one_dark`

### Requirement: The color depth follows the terminal
Colors SHALL be written as 24-bit SGR sequences (`38;2;r;g;b`, `48;2;r;g;b`) when `COLORTERM` is `truecolor` or `24bit`, as 256-color sequences (`38;5;n`, `48;5;n`) otherwise, and as the 16 basic colors (`30`-`37`, `90`-`97`, `40`-`47`, `100`-`107`) when `TERM` names a 16-color terminal (`linux`, `ansi`, `vt100`, `vt102`, `vt220`, `cons25`, `xterm-color`, or a name ending in `-16color`). The environment is read once when the editor starts. At 256 colors a palette color SHALL be written as the palette's own 256-color index when it gives one, otherwise as the nearest color of the 256-color palette. At 16 colors a group SHALL be written with its 16-color attributes, so a group whose palette color has no basic color still differs from `Normal`: the selection in reverse video and the cursor line underlined.

#### Scenario: Truecolor
- **WHEN** `COLORTERM` is `truecolor` and a Comment cell is written with `one_dark`
- **THEN** the cell is preceded by `38;2;` and the three components of the palette's Comment color

#### Scenario: 256 colors
- **WHEN** `COLORTERM` is unset, `TERM` is `xterm-256color`, and a Comment cell is written with `one_dark`
- **THEN** the cell is preceded by `38;5;` and the index of the nearest color of the 256-color palette

#### Scenario: The palette's own 256-color index
- **WHEN** a Comment cell is written at 256 colors with `dark_plus`, whose comment green would fall below the contrast rule at its nearest index
- **THEN** the cell is preceded by `38;5;71`

#### Scenario: 16 colors
- **WHEN** `TERM` is `linux` and a Comment cell is written
- **THEN** the cell is preceded by the palette's 16-color code for Comment, between `30` and `37` or `90` and `97`

#### Scenario: 16-color attribute fallback
- **WHEN** `TERM` is `linux` and a selected cell is written
- **THEN** the cell is preceded by `\e[0;7m`

## ADDED Requirements

### Requirement: The background option chooses who paints the background
The `option.background` line SHALL take `terminal` (the default) or `theme`. With `terminal`, `Normal` SHALL keep the terminal's own colors and every group without a background of its own the terminal's background. With `theme`, every cell, blank cells and the cleared screen included, SHALL be drawn on the palette's background. Any other value SHALL be reported as `file:line: unknown background VALUE` and keep the value before it.

#### Scenario: Transparent by default
- **WHEN** the editor starts with the shipped configuration and writes a Normal cell
- **THEN** the cell is preceded by `\e[0m`

#### Scenario: The theme paints
- **WHEN** a configuration line is "option.background theme", the theme is `one_dark`, and a frame is first written in truecolor
- **THEN** the screen is cleared after `48;2;40;44;52`, the palette's background, and a Normal cell is preceded by the palette's foreground and background

#### Scenario: Scrolled-in rows are painted
- **WHEN** the background is `theme` and a window scrolls by a line
- **THEN** the scroll region is sent after the Normal sequence, so the row that came into view is cleared on the palette's background

#### Scenario: Unknown value
- **WHEN** the project file's first line is "option.background dark"
- **THEN** ".caratrc:1: unknown background dark" is reported and the background stays `terminal`

### Requirement: Text groups meet WCAG AA contrast
In every shipped palette, drawn with the theme's background, every group that carries text SHALL have a contrast ratio of at least 4.5:1 between its foreground and background, and every decoration group (`NonText`, `EndOfBuffer`, `WinSeparator`, `FloatBorder`, `Whitespace`, `SignColumn`, and the file-icon groups) at least 3:1, both at 24-bit colors and at the 256 colors written for them. `TabLineFill`, `PmenuSbar`, and `PmenuThumb`, which carry no text, are exempt.

#### Scenario: Every palette passes
- **WHEN** the contrast of every group of `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured
- **THEN** no text group is below 4.5:1 and no decoration group below 3:1

#### Scenario: Comments are readable
- **WHEN** the contrast of `one_dark`'s Comment is measured
- **THEN** it is at least 4.5:1
