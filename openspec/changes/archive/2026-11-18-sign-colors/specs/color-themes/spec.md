## MODIFIED Requirements

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

## ADDED Requirements

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
