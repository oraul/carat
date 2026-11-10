## MODIFIED Requirements

### Requirement: The editor's own highlights are groups too
The editor SHALL know 52 UI groups, the first 41 by Neovim's names, the status bar's eight after them, and the indent guides' two, `IblIndent` and `IblScope` as Neovim's indent-blankline plugin names them, and `FloatTitle`, the title on a float's top edge as Neovim names it, last, and SHALL draw its own parts in them, which every palette colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: The UI groups
- **WHEN** the editor's group table is listed
- **THEN** its UI groups are `Normal`, `LineNr`, `StatusLine`, `ErrorMsg`, `NonText`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `SignColumn`, `Search`, `IncSearch`, `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `MoreMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`, `StatusLineModeNormal`, `StatusLineModeInsert`, `StatusLineModeVisual`, `StatusLineModeReplace`, `StatusLineModeCommand`, `StatusLineLspStarting`, `StatusLineLspReady`, `StatusLineLspError`, `IblIndent`, `IblScope`, and `FloatTitle`

#### Scenario: A plugin asks for an editor group
- **WHEN** a plugin asks for the group `StatusLine`
- **THEN** the request fails with `No highlight group named StatusLine`

#### Scenario: The search groups have colors
- **WHEN** any shipped palette is chosen
- **THEN** `Search`, `IncSearch`, and `CurSearch` have a background color at 24-bit, 256, and 16 colors

#### Scenario: Every UI group has a color in every palette
- **WHEN** any shipped palette is chosen with the theme's background
- **THEN** every UI group has a 24-bit foreground and background

