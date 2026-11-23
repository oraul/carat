## MODIFIED Requirements

### Requirement: The editor's own highlights are groups too
The editor SHALL know 62 UI groups, by the names the scenario lists: Neovim's 40, the status bar's twelve, indent-blankline's `IblIndent` and `IblScope`, Neovim's `FloatTitle`, Neovim's popup menu groups `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, and `PmenuExtraSel`, and last Neovim's `Added`, `Changed`, and `Removed`; it SHALL draw its own parts in them, which every palette colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: The UI groups
- **WHEN** the editor's group table is listed
- **THEN** its UI groups are `Normal`, `LineNr`, `StatusLine`, `ErrorMsg`, `NonText`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `SignColumn`, `Search`, `IncSearch`, `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`, `StatusLineModeNormal`, `StatusLineModeInsert`, `StatusLineModeVisual`, `StatusLineModeReplace`, `StatusLineModeCommand`, `StatusLineLspStarting`, `StatusLineLspReady`, `StatusLineLspError`, `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, `StatusLineDiagnosticHint`, `IblIndent`, `IblScope`, `FloatTitle`, `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, `PmenuExtraSel`, `Added`, `Changed`, and `Removed`

#### Scenario: A plugin asks for an editor group
- **WHEN** a plugin asks for the group `StatusLine`
- **THEN** the request fails with `No highlight group named StatusLine`

#### Scenario: The search groups have colors
- **WHEN** any shipped palette is chosen
- **THEN** `Search`, `IncSearch`, and `CurSearch` have a background color at 24-bit, 256, and 16 colors

#### Scenario: Every UI group has a color in every palette
- **WHEN** any shipped palette is chosen with the theme's background
- **THEN** every UI group has a 24-bit foreground and background

### Requirement: The message row has its own groups
The groups the message row draws SHALL have a row in every palette: `MsgDim` in the dim role, `ErrorMsg` in bold red, `WarningMsg` in yellow without bold, `ModeMsg` in bold normal text, and `Question`.

#### Scenario: The groups in the carat themes
- **WHEN** `MsgDim`, `ErrorMsg`, `WarningMsg`, and `ModeMsg` are looked up in `carat-dark` and in `carat-light`
- **THEN** their foregrounds are the palette's dim, red, yellow, and normal text, and `ErrorMsg` and `ModeMsg` are bold
