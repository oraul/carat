## MODIFIED Requirements

### Requirement: Frame layout for several windows
The frame SHALL show every window in its own rectangle: stacked windows are divided by a separator row of "─" ("-" with `option.icons ascii`) across the upper window's width, side-by-side windows by one separator column of "│" ("|" with `option.icons ascii`) down to the status bar, every separator in `WinSeparator` but a sidebar's edge. Each window SHALL have its own gutter and text area, rows past its buffer's end SHALL show "~", and the message row SHALL stay the last row.

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

### Requirement: A sidebar meets the editor by its background
A sidebar window SHALL be drawn on the sidebar layer of groups, and the column between it and the editor SHALL be a blank cell of that layer with no glyph. Where the terminal shows no background change, under `NO_COLOR` or at 16 colors, the separator glyph SHALL stay as the edge.

#### Scenario: A sidebar beside the editor draws no separator glyph
- **WHEN** a sidebar window 12 columns wide and the editor are shown side by side at 256 colors, and then the editor is split in two
- **THEN** every cell of the sidebar, its blank cell at column 12 included, is in the sidebar layer, no cell before the split is in `WinSeparator`, and after it the only separator glyph is "│" between the two editor windows

#### Scenario: Without a background change the sidebar keeps its edge
- **WHEN** the same frame is drawn under `NO_COLOR`, and again at 16 colors
- **THEN** column 12 holds "│" in `WinSeparator`, and drawn again at 256 colors it holds the blank cell
