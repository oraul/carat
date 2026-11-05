## MODIFIED Requirements

### Requirement: The editor's own highlights are groups too
The editor SHALL know 53 UI groups, the first 41 by Neovim's names and the status bar's twelve after them, and SHALL draw its own parts in them, which every palette colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: The UI groups
- **WHEN** the editor's group table is listed
- **THEN** its UI groups are `Normal`, `LineNr`, `StatusLine`, `ErrorMsg`, `NonText`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `SignColumn`, `Search`, `IncSearch`, `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `MoreMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`, `StatusLineModeNormal`, `StatusLineModeInsert`, `StatusLineModeVisual`, `StatusLineModeReplace`, `StatusLineModeCommand`, `StatusLineError`, `StatusLineWarn`, `StatusLineInfo`, `StatusLineHint`, `StatusLineLspStarting`, `StatusLineLspReady`, and `StatusLineLspError`

#### Scenario: A plugin asks for an editor group
- **WHEN** a plugin asks for the group `StatusLine`
- **THEN** the request fails with `No highlight group named StatusLine`

#### Scenario: The search groups have colors
- **WHEN** any shipped palette is chosen
- **THEN** `Search`, `IncSearch`, and `CurSearch` have a background color at 24-bit, 256, and 16 colors

#### Scenario: Every UI group has a color in every palette
- **WHEN** any shipped palette is chosen with the theme's background
- **THEN** every UI group has a 24-bit foreground and background

## ADDED Requirements

### Requirement: The mode pills read on their accents
In every shipped palette the mode pills SHALL be drawn bold in the palette's color for text on a strong accent over the mode's accent: blue for normal, green for insert, purple for visual, red for replace, and yellow for command-line, at 4.5:1 or more at 24-bit and 256 colors.

#### Scenario: Every palette's pills pass
- **WHEN** the contrast of the five pill groups of the four palettes is measured
- **THEN** none is below 4.5:1

### Requirement: The bar's slots read on the inactive panel
In every shipped palette the diagnostics and `lsp` groups SHALL be drawn in the accent of their kind or state over the inactive panel background: error and the `lsp` error red, warning and starting yellow, info blue, hint cyan, and ready green, at 4.5:1 or more at 24-bit and 256 colors.

#### Scenario: Every palette's slots pass
- **WHEN** the contrast of the seven slot groups of the four palettes is measured
- **THEN** none is below 4.5:1
