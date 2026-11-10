## MODIFIED Requirements

### Requirement: The editor's own highlights are groups too
The editor SHALL know 51 UI groups, the first 41 by Neovim's names, the status bar's eight after them, and the indent guides' two, `IblIndent` and `IblScope` as Neovim's indent-blankline plugin names them, last, and SHALL draw its own parts in them, which every palette colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: The UI groups
- **WHEN** the editor's group table is listed
- **THEN** its UI groups are `Normal`, `LineNr`, `StatusLine`, `ErrorMsg`, `NonText`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `SignColumn`, `Search`, `IncSearch`, `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `MoreMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`, `StatusLineModeNormal`, `StatusLineModeInsert`, `StatusLineModeVisual`, `StatusLineModeReplace`, `StatusLineModeCommand`, `StatusLineLspStarting`, `StatusLineLspReady`, `StatusLineLspError`, `IblIndent`, and `IblScope`

#### Scenario: A plugin asks for an editor group
- **WHEN** a plugin asks for the group `StatusLine`
- **THEN** the request fails with `No highlight group named StatusLine`

#### Scenario: The search groups have colors
- **WHEN** any shipped palette is chosen
- **THEN** `Search`, `IncSearch`, and `CurSearch` have a background color at 24-bit, 256, and 16 colors

#### Scenario: Every UI group has a color in every palette
- **WHEN** any shipped palette is chosen with the theme's background
- **THEN** every UI group has a 24-bit foreground and background

### Requirement: Text groups meet WCAG AA contrast
In every shipped palette, drawn with the theme's background, every group that carries text SHALL have a contrast ratio of at least 4.5:1 between its foreground and background, and every decoration group (`NonText`, `EndOfBuffer`, `WinSeparator`, `FloatBorder`, `Whitespace`, `SignColumn`, `IblIndent`, `IblScope`, and the file-icon groups) at least 3:1, both at 24-bit colors and at the 256 colors written for them. `TabLineFill`, `PmenuSbar`, and `PmenuThumb`, which carry no text, are exempt.

#### Scenario: Every palette passes
- **WHEN** the contrast of every group of `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured
- **THEN** no text group is below 4.5:1 and no decoration group below 3:1

#### Scenario: Comments are readable
- **WHEN** the contrast of `one_dark`'s Comment is measured
- **THEN** it is at least 4.5:1
