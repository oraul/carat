# Spec Delta

## MODIFIED Requirements

### Requirement: The editor's own highlights are groups too
The editor SHALL know 60 UI groups, by the names the scenario lists: Neovim's 41, the status bar's twelve, indent-blankline's `IblIndent` and `IblScope`, Neovim's `FloatTitle`, and last Neovim's popup menu groups `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, and `PmenuExtraSel`; it SHALL draw its own parts in them, which every palette colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: The UI groups
- **WHEN** the editor's group table is listed
- **THEN** its UI groups are `Normal`, `LineNr`, `StatusLine`, `ErrorMsg`, `NonText`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `SignColumn`, `Search`, `IncSearch`, `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `MoreMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`, `StatusLineModeNormal`, `StatusLineModeInsert`, `StatusLineModeVisual`, `StatusLineModeReplace`, `StatusLineModeCommand`, `StatusLineLspStarting`, `StatusLineLspReady`, `StatusLineLspError`, `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, `StatusLineDiagnosticHint`, `IblIndent`, `IblScope`, `FloatTitle`, `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, and `PmenuExtraSel`

#### Scenario: A plugin asks for an editor group
- **WHEN** a plugin asks for the group `StatusLine`
- **THEN** the request fails with `No highlight group named StatusLine`

#### Scenario: The search groups have colors
- **WHEN** any shipped palette is chosen
- **THEN** `Search`, `IncSearch`, and `CurSearch` have a background color at 24-bit, 256, and 16 colors

#### Scenario: Every UI group has a color in every palette
- **WHEN** any shipped palette is chosen with the theme's background
- **THEN** every UI group has a 24-bit foreground and background

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

## ADDED Requirements

### Requirement: The diagnostics counts read on the status bar's background
In every shipped palette the status bar's count groups, `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, and `StatusLineDiagnosticHint`, SHALL be drawn over the background of `StatusLine` at 24-bit, 256, and 16 colors, error in the bar's red, warning in its yellow, info in its blue, and hint in its cyan, each at 4.5:1 or more on the bar at 24-bit and 256 colors.

#### Scenario: The count groups share the bar's background
- **WHEN** the backgrounds of the four count groups and of `StatusLine` of the six shipped palettes are read, with the terminal's background and with the theme's, at every color depth
- **THEN** each count group's background equals the `StatusLine` background

#### Scenario: Every palette's count groups pass on the bar
- **WHEN** the contrast of the four count groups of the six shipped palettes is measured on their own background
- **THEN** none is below 4.5:1 at 24-bit or at 256 colors
