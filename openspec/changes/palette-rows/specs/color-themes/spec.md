## MODIFIED Requirements

### Requirement: The editor's own highlights are groups too
The editor SHALL know 56 UI groups, by the names the scenario lists: Neovim's 41, the status bar's eight, indent-blankline's `IblIndent` and `IblScope`, Neovim's `FloatTitle`, and last Neovim's popup menu groups `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, and `PmenuExtraSel`; it SHALL draw its own parts in them, which every palette colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: The UI groups
- **WHEN** the editor's group table is listed
- **THEN** its UI groups are `Normal`, `LineNr`, `StatusLine`, `ErrorMsg`, `NonText`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `SignColumn`, `Search`, `IncSearch`, `CurSearch`, `CursorLine`, `CursorLineNr`, `ColorColumn`, `EndOfBuffer`, `WinSeparator`, `Directory`, `Title`, `WarningMsg`, `ModeMsg`, `MoreMsg`, `Question`, `MatchParen`, `Pmenu`, `PmenuSel`, `PmenuSbar`, `PmenuThumb`, `NormalFloat`, `FloatBorder`, `DiffAdd`, `DiffChange`, `DiffDelete`, `DiffText`, `Whitespace`, `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`, `StatusLineModeNormal`, `StatusLineModeInsert`, `StatusLineModeVisual`, `StatusLineModeReplace`, `StatusLineModeCommand`, `StatusLineLspStarting`, `StatusLineLspReady`, `StatusLineLspError`, `IblIndent`, `IblScope`, `FloatTitle`, `PmenuMatch`, `PmenuMatchSel`, `PmenuExtra`, and `PmenuExtraSel`

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

### Requirement: A selected menu row keeps 4.5:1 at every color depth
The groups of a menu's selected row, `PmenuSel`, `PmenuMatchSel`, and `PmenuExtraSel`, SHALL each reach 4.5:1 between foreground and background inside a float at 24 bits and at 256 colors in every shipped palette, and at 16 colors SHALL be drawn in reverse video with `PmenuSel`'s colors, so the selected row reads in the terminal's own pair.

#### Scenario: The selected menu row's groups at each depth
- **WHEN** any shipped palette is chosen, with the theme's background or the terminal's
- **THEN** `PmenuSel`, `PmenuMatchSel`, and `PmenuExtraSel` reach 4.5:1 inside a float at 24 bits and at 256 colors, and at 16 colors carry reverse video and `PmenuSel`'s 16-color foreground and background
