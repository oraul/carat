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
The editor SHALL draw its own parts in the groups `Normal`, `LineNr`, `SignColumn`, `StatusLine`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `NonText`, `ErrorMsg`, `Search`, and `IncSearch`, which a theme colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: A plugin asks for an editor group
- **WHEN** a plugin asks for the group `StatusLine`
- **THEN** the request fails with `No highlight group named StatusLine`

#### Scenario: The search groups have colors
- **WHEN** either shipped theme is chosen
- **THEN** `Search` and `IncSearch` have a background color in both color depths

### Requirement: The theme option selects a shipped theme
The `option.theme` line of the configuration SHALL select the theme, `carat-dark` (the default) or `carat-light`; an unknown name SHALL be reported as `file:line: unknown theme NAME` and keep the theme set before it. A theme gives every group a foreground and a background (or the terminal's own) and any of bold, italic, underline, and reverse; `Normal` keeps the terminal's own colors in both themes.

#### Scenario: Default theme
- **WHEN** the editor starts with the shipped configuration
- **THEN** the colors are those of `carat-dark`

#### Scenario: Light theme
- **WHEN** a configuration line is "option.theme carat-light"
- **THEN** the Comment group is written with `carat-light`'s comment color

#### Scenario: Unknown theme
- **WHEN** the project file's first line is "option.theme solarized"
- **THEN** ".caratrc:1: unknown theme solarized" is reported and the colors are those of `carat-dark`

### Requirement: Editor highlights take their colors from the theme
The status lines, the tab line, the line numbers, the sign column, the tilde rows, the selection, and error messages SHALL be written in the colors and attributes the theme gives their groups.

#### Scenario: Status line
- **WHEN** a frame with a status line is written in truecolor with `carat-dark`
- **THEN** the status line's cells are preceded by the foreground and background of `carat-dark`'s StatusLine

### Requirement: The color depth follows the terminal
Colors SHALL be written as 24-bit SGR sequences (`38;2;r;g;b`, `48;2;r;g;b`) when `COLORTERM` is `truecolor` or `24bit`, as 256-color sequences (`38;5;n`, `48;5;n`) otherwise, and as the 16 basic colors (`30`-`37`, `90`-`97`, `40`-`47`, `100`-`107`) when `TERM` names a 16-color terminal (`linux`, `ansi`, `vt100`, `vt102`, `vt220`, `cons25`, `xterm-color`, or a name ending in `-16color`). The environment is read once when the editor starts.

#### Scenario: Truecolor
- **WHEN** `COLORTERM` is `truecolor` and a Comment cell is written with `carat-dark`
- **THEN** the cell is preceded by `38;2;` and the three components of the theme's Comment color

#### Scenario: 256 colors
- **WHEN** `COLORTERM` is unset, `TERM` is `xterm-256color`, and a Comment cell is written
- **THEN** the cell is preceded by `38;5;` and the index of the nearest color of the 256-color palette

#### Scenario: 16 colors
- **WHEN** `TERM` is `linux` and a Comment cell is written
- **THEN** the cell is preceded by the theme's 16-color code for Comment, between `30` and `37` or `90` and `97`
