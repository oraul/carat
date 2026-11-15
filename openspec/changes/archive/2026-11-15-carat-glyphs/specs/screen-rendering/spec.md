## MODIFIED Requirements

### Requirement: Frame layout for several windows
The frame SHALL show every window of the current tab page in its own rectangle: stacked windows are divided by a separator row of "─" ("-" with `option.icons ascii`) across the upper window's width, side-by-side windows by one separator column of "│" ("|" with `option.icons ascii`) down to the status bar, every separator in `WinSeparator`. Each window SHALL have its own gutter and text area, rows past its buffer's end SHALL show "~", and the message row SHALL stay the last row.

#### Scenario: Two stacked windows
- **WHEN** the lines ["one", "two", "three"] are shown in a window split horizontally in a 9-row, 14-column frame
- **THEN** rows 0 to 2 read "  1 one", "  2 two", "  3 three", row 3 is a separator row of "─" in `WinSeparator`, rows 4 to 6 read the same three lines, row 7 is the status bar, and row 8 is the message row

#### Scenario: Two windows side by side
- **WHEN** the lines ["one", "two"] are shown in a window split vertically in a 6-row, 21-column frame
- **THEN** row 0 reads "  1 one   │  1 one", with the separator at column 10 in `WinSeparator`, row 4 is the status bar across all 21 columns, and row 5 is the message row

#### Scenario: ASCII separators
- **WHEN** `option.icons` is "ascii" and a window is split vertically and then horizontally
- **THEN** the separator column reads "|" and the separator row reads "-" across its width, both in `WinSeparator`

## ADDED Requirements

### Requirement: An ASCII frame under the ascii icon set
With `option.icons ascii` and buffer text that is ASCII, every cell of the frame SHALL hold an ASCII character: the tabs, the window separators, the status bar with its icons and progress bar, and the message row.

#### Scenario: No byte above 127 in an ascii frame
- **WHEN** `option.icons` is "ascii", two files are listed as tabs, the window is split vertically and horizontally, the buffer is modified, and work reports 40 percent
- **THEN** no cell of the frame holds a code point above 127
