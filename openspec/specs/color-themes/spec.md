# color-themes Specification

## Purpose
Decides how each highlight group looks on the terminal: the group table, the shipped themes, the theme option, and the color depth the output uses.

## Requirements

### Requirement: Highlight groups have Neovim's standard names
The editor SHALL know the syntax groups `Comment`, `Constant`, `String`, `Character`, `Number`, `Boolean`, `Float`, `Identifier`, `Function`, `Statement`, `Conditional`, `Repeat`, `Label`, `Operator`, `Keyword`, `Exception`, `PreProc`, `Include`, `Define`, `Macro`, `Type`, `StorageClass`, `Structure`, `Typedef`, `Special`, `SpecialChar`, `Delimiter`, `SpecialComment`, `Todo`, and `Error`, by these names.

#### Scenario: A plugin resolves a group
- **WHEN** a plugin asks for the group `Comment`
- **THEN** it receives the id of the Comment group

#### Scenario: An unknown group
- **WHEN** a plugin asks for the group `Banana`
- **THEN** the request fails with `No highlight group named Banana`

### Requirement: The editor's own highlights are groups too
The editor SHALL know 63 UI groups, by the names the scenario lists: Neovim's 41, the status bar's twelve, indent-blankline's `IblIndent` and `IblScope`, Neovim's `FloatTitle`, Neovim's popup menu groups `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, and `PmenuExtraSel`, and last Neovim's `Added`, `Changed`, and `Removed`; it SHALL draw its own parts in them, which every palette colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: The UI groups
- **WHEN** the editor's group table is listed
- **THEN** its UI groups are `Normal`, `LineNr`, `StatusLine`, `ErrorMsg`, `NonText`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `SignColumn`, `Search`, `IncSearch`, `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `MoreMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`, `StatusLineModeNormal`, `StatusLineModeInsert`, `StatusLineModeVisual`, `StatusLineModeReplace`, `StatusLineModeCommand`, `StatusLineLspStarting`, `StatusLineLspReady`, `StatusLineLspError`, `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, `StatusLineDiagnosticHint`, `IblIndent`, `IblScope`, `FloatTitle`, `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, `PmenuExtraSel`, `Added`, `Changed`, and `Removed`

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

### Requirement: Each palette colors every group
Each palette SHALL give the syntax groups its own colors, and every group a foreground and a background (or the terminal's own) and any of bold, italic, underline, and reverse.

#### Scenario: Palettes differ in their syntax colors
- **WHEN** a Keyword cell is written with `one_dark` and with `dark_plus`
- **THEN** the two foregrounds differ

### Requirement: Editor highlights take their colors from the theme
The status lines, the tab line, the line numbers, the sign column, the tilde rows, the selection, and error messages SHALL be written in the colors and attributes the theme gives their groups.

#### Scenario: Status line
- **WHEN** a frame with a status line is written in truecolor with `carat-dark`
- **THEN** the status line's cells are preceded by the foreground and background of `carat-dark`'s StatusLine

### Requirement: The color depth follows the terminal
Colors SHALL be written as 24-bit SGR sequences (`38;2;r;g;b`, `48;2;r;g;b`) when `COLORTERM` is `truecolor` or `24bit`, as 256-color sequences (`38;5;n`, `48;5;n`) otherwise, and as the 16 basic colors (`30`-`37`, `90`-`97`, `40`-`47`, `100`-`107`) when `TERM` names a 16-color terminal (`linux`, `ansi`, `vt100`, `vt102`, `vt220`, `cons25`, `xterm-color`, or a name ending in `-16color`). The environment is read once when the editor starts.

#### Scenario: Truecolor
- **WHEN** `COLORTERM` is `truecolor` and a Comment cell is written with `one_dark`
- **THEN** the cell is preceded by `38;2;` and the three components of the palette's Comment color

#### Scenario: 256 colors
- **WHEN** `COLORTERM` is unset, `TERM` is `xterm-256color`, and a Comment cell is written with `one_dark`
- **THEN** the cell is preceded by `38;5;` and the index of the nearest color of the 256-color palette

#### Scenario: 16 colors
- **WHEN** `TERM` is `linux` and a Comment cell is written
- **THEN** the cell is preceded by the palette's 16-color code for Comment, between `30` and `37` or `90` and `97`

### Requirement: Palette colors fall back by color depth
At 256 colors a palette color SHALL be written as the palette's own 256-color index when it gives one, otherwise as the nearest color of the 256-color palette. At 16 colors a group SHALL be written with its 16-color attributes, so a group whose palette color has no basic color still differs from `Normal`: the selection in reverse video and the cursor line underlined.

#### Scenario: The palette's own 256-color index
- **WHEN** a Comment cell is written at 256 colors with `dark_plus`, whose comment green would fall below the contrast rule at its nearest index
- **THEN** the cell is preceded by `38;5;71`

#### Scenario: 16-color attribute fallback
- **WHEN** `TERM` is `linux` and a selected cell is written
- **THEN** the cell is preceded by `\e[0;7m`

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

### Requirement: The cursor line at 16 colors
At 16 colors a group without a background of its own SHALL be underlined on the cursor line and SHALL keep the background it has off the line, the theme's painted background included.

#### Scenario: Sixteen colors
- **WHEN** a Comment cell on the cursor line is written to a 16-color terminal
- **THEN** its sequence underlines it and keeps Comment's color

#### Scenario: Sixteen colors on the theme's background
- **WHEN** the theme's background is painted and a Normal or Comment cell on the cursor line is written to a 16-color terminal
- **THEN** it keeps Normal's 16-color background and is underlined

### Requirement: The mode pills read on their accents
In every shipped palette the mode pills SHALL be drawn bold in the palette's color for text on a strong accent over the mode's accent: blue for normal, green for insert, purple for visual, red for replace, and cyan for the command line and every query picker's prompt, at 4.5:1 or more at 24-bit and 256 colors.

#### Scenario: Every palette's pills pass
- **WHEN** the contrast of the five pill groups of the six shipped palettes is measured
- **THEN** none is below 4.5:1

#### Scenario: The command pill is cyan
- **WHEN** the command line or a query picker's prompt is open in any shipped palette
- **THEN** the pill is drawn in `StatusLineModeCommand`, the palette's text on a strong accent over its cyan, bold

### Requirement: Markup groups for documentation
The group table SHALL hold six markup groups after the file-icon groups, named as Neovim's tree-sitter captures, which every shipped palette SHALL color and each SHALL show at 16 colors by a basic color or an attribute. A plugin token MAY carry a markup group.

#### Scenario: The markup groups by name
- **WHEN** the group names after the file-icon groups are listed
- **THEN** they are `@markup.heading`, `@markup.strong`, `@markup.italic`, `@markup.raw`, `@markup.link.label`, and `@markup.raw.block`, and a plugin token may name each

#### Scenario: The markup groups' looks
- **WHEN** `one_dark` is drawn
- **THEN** `@markup.heading` is blue and bold, `@markup.strong` the text color and bold, `@markup.italic` the text color and italic, `@markup.raw` the string color, `@markup.link.label` cyan and underlined, and `@markup.raw.block` dim gray

### Requirement: Groups in a float stay readable over its background
A syntax or markup group drawn inside a float SHALL keep its foreground and attributes and take NormalFloat's background unless it has a background of its own. In every shipped palette, drawn with the theme's background, every syntax and markup group that carries text SHALL have a contrast of at least 4.5:1 over that background, at 24-bit colors and at the 256 colors written for them.

#### Scenario: Every palette passes in a float
- **WHEN** the contrast of every syntax and markup group of the six shipped palettes is measured over the float background
- **THEN** none is below 4.5:1

### Requirement: A selected menu row keeps 4.5:1 at every color depth
The groups of a menu's selected row, `PmenuSel`, `PmenuMatchSel`, and `PmenuExtraSel`, SHALL each reach 4.5:1 between foreground and background inside a float at 24 bits and at 256 colors in every shipped palette, and at 16 colors SHALL be drawn in reverse video with `PmenuSel`'s colors, so the selected row reads in the terminal's own pair.

#### Scenario: The selected menu row's groups at each depth
- **WHEN** any shipped palette is chosen, with the theme's background or the terminal's
- **THEN** with the theme's background `PmenuSel`, `PmenuMatchSel`, and `PmenuExtraSel` reach 4.5:1 inside a float at 24 bits and at 256 colors, and under either background at 16 colors they carry reverse video and `PmenuSel`'s 16-color foreground and background

### Requirement: The lsp slot reads on the status bar's background
In every shipped palette the `lsp` groups SHALL be drawn over the status bar's own background, the background of `StatusLine`, at 24-bit, 256, and 16 colors, so the bar shows as one band, each in the accent of its state picked for that bar: starting yellow, ready green, and error red and bold, at 4.5:1 or more on the bar at 24-bit and 256 colors, and at 16 colors at 4.5:1 or more under xterm's default colors, an accent no basic color can give there taking the bar's text color.

#### Scenario: The lsp groups share the bar's background
- **WHEN** the backgrounds of the three `lsp` groups and of `StatusLine` of the six shipped palettes are read, with the terminal's background and with the theme's, at every color depth
- **THEN** each `lsp` group's background equals the `StatusLine` background

#### Scenario: Every palette's lsp groups pass on the bar
- **WHEN** the contrast of the three `lsp` groups of the six shipped palettes is measured on their own background
- **THEN** none is below 4.5:1 at 24-bit or at 256 colors

#### Scenario: The bar reads at 16 colors
- **WHEN** the 16-color foreground and background of `StatusLine`, the three `lsp` groups, and the four status bar count groups of the six shipped palettes are measured under xterm's default colors
- **THEN** none is below 4.5:1, so the slot's starting and ready text no longer reads near 1.5:1 on a light gray bar

### Requirement: The diagnostics counts read on the status bar's background
In every shipped palette the status bar's count groups, `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, and `StatusLineDiagnosticHint`, SHALL be drawn over the background of `StatusLine` at 24-bit, 256, and 16 colors, error in the bar's red, warning in its yellow, info in its blue, and hint in its cyan, each at 4.5:1 or more on the bar at 24-bit and 256 colors.

#### Scenario: The count groups share the bar's background
- **WHEN** the backgrounds of the four count groups and of `StatusLine` of the six shipped palettes are read, with the terminal's background and with the theme's, at every color depth
- **THEN** each count group's background equals the `StatusLine` background

#### Scenario: Every palette's count groups pass on the bar
- **WHEN** the contrast of the four count groups of the six shipped palettes is measured on their own background
- **THEN** none is below 4.5:1 at 24-bit or at 256 colors

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
`carat-light`'s selection SHALL be #c2ccef, at least 1.5:1 from its background, and its panel surfaces #eceef3. At 256 colors `carat-dark`'s panel surfaces SHALL be index 233, apart from the background's 234.

#### Scenario: The light selection shows
- **WHEN** `carat-light`'s `Visual` is drawn
- **THEN** its background is #c2ccef, above 1.26:1 and at least 1.5:1 from the background

#### Scenario: The panel colors
- **WHEN** `carat-dark` and `carat-light` are drawn
- **THEN** `carat-light`'s `TabLine` and `NormalFloat` backgrounds are #eceef3, and `carat-dark`'s `TabLine` background is index 233 at 256 colors while `Normal`'s is 234

### Requirement: The background option paints the theme by default
The `option.background` line SHALL take `theme`, the default, or `terminal`. With `theme` every cell, the cleared screen included, SHALL be drawn on the palette's background; with `terminal`, `Normal` SHALL keep the terminal's own colors and every group without a background of its own the terminal's background. A background or theme a configuration line names SHALL be kept. Any other value SHALL be reported as `file:line: unknown background VALUE` and keep the value before it.

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

### Requirement: Each sign is drawn in the group of its kind
A sign SHALL be drawn in the highlight group of its icon: `error` in `DiagnosticError`, `warning` in `DiagnosticWarn`, `info` in `DiagnosticInfo`, `hint` in `DiagnosticHint`, `git_added` in `Added`, `git_changed` in `Changed`, `git_deleted` in `Removed`, and any other icon in `SignColumn`; a diagnostic sign SHALL take the group of its severity, and empty sign cells stay in `SignColumn`.

#### Scenario: Diagnostic signs are red and yellow
- **WHEN** an error sign is on row 0 and a warning sign on row 1, with carat-dark and with carat-light
- **THEN** the frame draws the error glyph in `DiagnosticError`, written in the palette's red, and the warning glyph in `DiagnosticWarn`, written in its yellow

#### Scenario: Git signs are green and cyan
- **WHEN** the git signs plugin marks row 0 added and row 1 changed, with carat-dark and with carat-light
- **THEN** the frame draws the added glyph in `Added`, written in the palette's green, and the changed glyph in `Changed`, written in its cyan

#### Scenario: A sign of another icon keeps the sign column's group
- **WHEN** a plugin places a sign with the icon `ruby`
- **THEN** its glyph is drawn in `SignColumn`

#### Scenario: A diagnostic sign takes its severity's group
- **WHEN** a language server publishes an error on row 0 and a warning on row 1
- **THEN** the sign of row 0 is in `DiagnosticError` and that of row 1 in `DiagnosticWarn`

### Requirement: Signs keep their colors in every palette
Every palette SHALL color `Added` green, `Changed` cyan, and `Removed` red, as it colors `DiagnosticError` red and `DiagnosticWarn` yellow.

#### Scenario: The git sign groups are green, cyan, and red
- **WHEN** any shipped palette is chosen
- **THEN** `Added` takes the palette's green, `Changed` its cyan, and `Removed` its red

### Requirement: The message row has its own groups
The groups the message row draws SHALL have a row in every palette: `MsgDim` in the dim role, `ErrorMsg` in bold red, `WarningMsg` in yellow without bold, `MoreMsg` in bold blue, and `Question`.

#### Scenario: The groups in the carat themes
- **WHEN** `MsgDim`, `ErrorMsg`, `WarningMsg`, and `MoreMsg` are looked up in `carat-dark` and in `carat-light`
- **THEN** their foregrounds are the palette's dim, red, yellow, and blue, and `ErrorMsg` and `MoreMsg` are bold

### Requirement: Whitespace marks take the guides' color
Every palette SHALL color `Whitespace` with the color role of `IblIndent`, so the marks of `option.list` are as quiet as the indent guides: #30364b in `carat-dark`, #d8dce8 in `carat-light`, and basic color 8 at 16 colors in every palette. In `carat-dark` and `carat-light` it SHALL recede with `IblIndent` below `Comment`, and in the other palettes keep the decorations' 3:1.

#### Scenario: The whitespace marks take the guide color
- **WHEN** each shipped palette is drawn
- **THEN** `Whitespace` has `IblIndent`'s color at 24 bits and at 16 colors, #30364b on `carat-dark` and #d8dce8 on `carat-light`, basic color 8 at 16 colors

#### Scenario: The other palettes' whitespace marks keep 3:1
- **WHEN** the contrast of `Whitespace` of `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured on the background and on the cursor line, at 24-bit colors and at 256 colors
- **THEN** it is not below 3:1

### Requirement: The colorscheme command switches the palette at once
`:colo[rscheme] <name>` SHALL make the shipped palette of that name the theme at once: the next frame SHALL be drawn in full, every cell in its group's colors in the new palette at the terminal's color depth, the background option kept, as at startup. `:set theme=<name>` and `:set background=<word>` SHALL repaint in the same way.

#### Scenario: Switching to each shipped palette
- **WHEN** `:colorscheme <name>` is run for each shipped palette name, from another palette, at 256 colors
- **THEN** the message row is empty, `:colorscheme` shows `<name>`, and the frame is written in full with every group it holds in `<name>`'s sequences

#### Scenario: Switching at 16 colors
- **WHEN** the palette changes on a terminal of 16 colors
- **THEN** the next frame is written in full with each group in the new palette's 16-color sequence

#### Scenario: Set theme repaints
- **WHEN** `:set theme=one_dark` is run
- **THEN** the frame is written in full with every group it holds in `one_dark`'s sequences

#### Scenario: Set background repaints
- **WHEN** `:set bg=terminal` is run
- **THEN** the frame is written in full and a Normal cell is preceded by `\e[0m`, the terminal's own colors

### Requirement: The colorscheme command refuses an unknown name and shows the current one
Another name than a shipped palette's SHALL answer `E185: Cannot find color scheme '<name>'` and keep the palette; `:colorscheme` with no name SHALL show the current palette's name.

#### Scenario: An unknown palette
- **WHEN** `:colorscheme solarized` is run
- **THEN** the message row shows `E185: Cannot find color scheme 'solarized'` and the palette is unchanged

#### Scenario: No name shows the current palette
- **WHEN** `:colorscheme` is run with the shipped configuration
- **THEN** the message row shows `carat-dark`

### Requirement: Folded has a row in every palette
Every palette SHALL give `Folded`, the group of a closed fold's row and the last UI group, the dim role as its foreground, no background of its own, and no attributes, so it shows at 24 bits, at 256 colors, and at 16 colors.

#### Scenario: Folded in the carat themes
- **WHEN** `Folded` is looked up in each shipped palette
- **THEN** its foreground is the palette's dim color at every depth, it has no background and no attributes, and its name is `Folded`

### Requirement: StatusLineDim reads on the bar in every palette
Every palette SHALL give `StatusLineDim`, the last UI group, the `PANEL_DIM` role as its foreground on the `PANEL` background of `StatusLine`, no attributes, and `PANEL_DIM` SHALL reach 4.5:1 on that background at 24 bits, at 256 colors, and at 16 colors under xterm's default colors, where `StatusLineDim` is the weight beside the bold `StatusLine`. `carat-dark`'s `PANEL_DIM` SHALL be `#a4aabd` and `carat-light`'s `#5c6173`.

#### Scenario: StatusLineDim is the bar's quiet text in every palette
- **WHEN** `StatusLineDim` is looked up in each shipped palette on either background choice
- **THEN** its foreground is the palette's `PANEL_DIM`, its background the bar's, it is not bold, its contrast on the bar is at least 4.5:1 at every depth, `StatusLine` is bold at 16 colors where it is not, and its name is `StatusLineDim`

### Requirement: The selected row's mark and label groups have a row in every palette
Every palette SHALL give `PmenuMarkSel` the `MARK` role (its blue, lighter in `dark_plus`) as its foreground and `PmenuLabelSel` the text role (`FG`), both on the `SELECTION` background of `PmenuSel` and bold; at 16 colors both SHALL be reverse and bold, as `PmenuSel` is reverse there. The bar SHALL read at 3:1 on the selection, as a decoration.

#### Scenario: The mark and label groups in every palette
- **WHEN** `PmenuMarkSel` and `PmenuLabelSel` are looked up in each shipped palette
- **THEN** the mark's foreground is the palette's `MARK` (the blue of the carat themes) reading at 3:1 or more on the selection and the label's its text color, both backgrounds are `PmenuSel`'s, both are bold at 24 bits and reverse and bold at 16 colors, and their names are `PmenuMarkSel` and `PmenuLabelSel`

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

### Requirement: The selected tab is bold on the editor's background
In every shipped palette `TabLineSel`, the group of the selected buffer tab, SHALL be drawn bold at every attribute depth in Normal's own foreground and background, so the selected tab takes the editor's background with no accent fill; `TabLineName`, the group of the current tab-page number, the current window's winbar name, and the shown view of a slot header, SHALL be drawn bold over the tab row's own background; `TabLine` SHALL not be bold, so the selected tab is never told by color alone.

#### Scenario: The selected tab is bold on the editor's background
- **WHEN** the tab groups of the six shipped palettes are measured, with the theme's background or the terminal's, and the sequences of carat-dark at 24 bits, 256 colors, and 16 colors are read
- **THEN** `TabLineSel` and `TabLineName` are bold and `TabLine` is not, `TabLineSel` has Normal's colors, and the sequence of `TabLineSel` has no accent background and is Normal's with the bold added at every depth
