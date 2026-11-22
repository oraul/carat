## ADDED Requirements

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
