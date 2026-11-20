# Spec Delta

## Purpose

Neovim's `list` and `listchars` options: marks over the tabs, trailing spaces, and no-break spaces of file windows, in a quiet color that never competes with the text.

## ADDED Requirements

### Requirement: The list option shows whitespace marks
With `option.list` on, every text row of a file window SHALL draw, in the `Whitespace` group, the `tab` mark over each cell a tab takes (its first character on the first cell, its second on the cells after, and its third, when given, on the last cell, which alone shows it on a one-cell tab), the `trail` mark over each space after the line's last other character, and the `nbsp` mark over each no-break space (U+00A0 or U+202F). With `option.list` off, the default in fresh options and in the shipped configuration, no mark SHALL be drawn and those cells show blanks as before.

#### Scenario: Marks with list on
- **WHEN** `option.list true` is set with the shipped `listchars` and a file line reads a tab, `a`, a no-break space, `b`, and two spaces
- **THEN** the row shows `→` and blanks over the tab's cells, `a`, `␣`, `b`, and `··`, the marks in `Whitespace`

#### Scenario: No marks with list off
- **WHEN** `option.list` is off and the same line is shown
- **THEN** the tab's cells, the no-break space, and the trailing spaces show blanks and no cell is in `Whitespace`

#### Scenario: A tab with a last mark
- **WHEN** `option.listchars` is `tab:<->` with `option.list true` and a line starts with a tab four cells wide, and another with a tab one cell wide
- **THEN** the first tab shows `<-->` and the second `>`

#### Scenario: Marks move with the horizontal scroll
- **WHEN** the window is scrolled sideways into the cells of a tab and the trailing spaces
- **THEN** only the visible cells of the tab and of the trailing spaces show their marks, at their scrolled columns

### Requirement: The listchars option names the marks
`option.listchars` SHALL take comma-separated `key:chars` items, the keys `tab` (two or three characters), `trail` (one), and `nbsp` (one), each character one column wide and not a control; a key left out draws no mark, a later item of a key wins, and an empty value draws none. Fresh options SHALL hold Neovim's default `tab:> ,trail:-,nbsp:+`. Another value SHALL be reported as `file:line: option.listchars takes tab:xy, trail:x, and nbsp:x, comma-separated, each one column wide`, the value before it kept.

#### Scenario: The shipped list options
- **WHEN** the shipped configuration is read
- **THEN** `list` is off and `listchars` is `tab:→ ,trail:·,nbsp:␣`, with no problem reported, and a line `option.list yes` is reported as `option.list takes true or false`

#### Scenario: A key left out draws no mark
- **WHEN** `option.listchars` is `trail:-` with `option.list true` and a line holds a tab and a trailing space
- **THEN** the tab's cells show blanks and the trailing space shows `-`

#### Scenario: A listchars value that does not read is refused
- **WHEN** a configuration line sets `option.listchars` to `eol:$`, `tab:>`, `trail:ab`, `nbsp:`, or a character two columns wide
- **THEN** the line is reported as `option.listchars takes tab:xy, trail:x, and nbsp:x, comma-separated, each one column wide` and the value before it is kept

### Requirement: The ASCII marks
With `option.icons ascii`, a mark outside ASCII SHALL be drawn in Neovim's default form: `>` for a tab's first and last mark and a blank for its middle, `-` for `trail`, and `+` for `nbsp`; a mark in ASCII SHALL be kept as set.

#### Scenario: The ASCII marks
- **WHEN** `option.icons ascii` is set with the shipped `listchars` and `option.list true`, and the line of the first scenario is shown
- **THEN** the row shows `>` and blanks over the tab's cells, `a`, `+`, `b`, and `--`, with no code point above 127

### Requirement: Marks only over file text
The marks SHALL be drawn only over the text of file windows: plugin windows (the explorer, pick lists), floats, and the row of a closed fold SHALL draw none. Under `NO_COLOR` the mark characters SHALL still be drawn.

#### Scenario: A plugin window draws no marks
- **WHEN** `option.list true` is set and a plugin's scratch buffer line holds a tab and trailing spaces
- **THEN** its row shows blanks there

#### Scenario: A closed fold's row draws no marks
- **WHEN** `option.list true` is set and a closed fold's first line holds a no-break space and trailing spaces
- **THEN** the fold's row shows its fold text with no cell in `Whitespace`

#### Scenario: Marks under NO_COLOR
- **WHEN** the terminal sets `NO_COLOR` and `option.list true` is set
- **THEN** the row still shows the tab, trailing, and no-break space marks
