## MODIFIED Requirements

### Requirement: Frame layout for one window
A frame of R rows and C columns showing one tab page with one window and no buffer tabs row SHALL use rows 0 to R-3 for the window, row R-2 for the status bar, and row R-1 for the command line or message. Every window row SHALL start with a line number gutter, right-aligned numbers of width max(3, digits of the line count) followed by one space, when the number option is on, and no gutter otherwise. Rows past the end of the buffer SHALL show "~" in column 0.

#### Scenario: Three lines in a six-row frame
- **WHEN** the lines ["one", "two", "three"] are rendered in 6 rows and 12 columns with number on
- **THEN** rows 0 to 2 read "  1 one", "  2 two", "  3 three", row 3 reads "~", row 4 is the status bar, and row 5 is the message row

#### Scenario: Number off
- **WHEN** the same lines are rendered with number off
- **THEN** row 0 reads "one" starting at column 0

#### Scenario: Wide gutter
- **WHEN** a buffer with 1000 lines is rendered with number on
- **THEN** the gutter is five columns wide and row 0 reads "   1 " followed by the text

### Requirement: Frame layout for several windows
The frame SHALL show every window of the current tab page in its own rectangle: a horizontal split stacks the windows, each window above another ending in a separator row of horizontal lines across its width, and the bottom windows reaching the status bar; a vertical split places them side by side with one separator column between them showing the vertical bar character down to the status bar. Every separator SHALL be drawn in the `WinSeparator` group. Each window SHALL have its own line number gutter and text area, and rows past the end of its buffer SHALL show "~". The command line or message row SHALL stay the last row of the frame.

#### Scenario: Two stacked windows
- **WHEN** the lines ["one", "two", "three"] are shown in a window split horizontally in a 9-row, 14-column frame
- **THEN** rows 0 to 2 read "  1 one", "  2 two", "  3 three", row 3 is a separator row of "─" in `WinSeparator`, rows 4 to 6 read the same three lines, row 7 is the status bar, and row 8 is the message row

#### Scenario: Two windows side by side
- **WHEN** the lines ["one", "two"] are shown in a window split vertically in a 6-row, 21-column frame
- **THEN** row 0 reads "  1 one   │  1 one", with the separator at column 10 in `WinSeparator`, row 4 is the status bar across all 21 columns, and row 5 is the message row

### Requirement: Only changed cells are written to the terminal
Each frame SHALL be written to the terminal in one write. The first frame and any frame after a size change SHALL be written in full; later frames SHALL write only the runs of cells that changed, each preceded by a cursor position, plus the cursor position and shape. Cells that did not change SHALL not be written, except unchanged cells shorter than a cursor position between two changed runs of one row, which may be written to join them.

#### Scenario: Identical frame writes nothing but the cursor
- **WHEN** a frame is presented twice
- **THEN** the second write contains no cell text

#### Scenario: One changed row
- **WHEN** the next frame differs in row 2 only
- **THEN** the write contains row 2's changed text and no other row's text

#### Scenario: Only the changed part of a row
- **WHEN** a row reads "hello world" and the next frame shows "hello there" on it
- **THEN** the write contains "there", positioned at the column of "t", and does not contain "hello"

#### Scenario: Moving the cursor writes only the ruler
- **WHEN** "l" is pressed in a buffer of 200-column lines shown in a 200-column terminal
- **THEN** the write contains the changed cursor column of the status bar and no text of the buffer

#### Scenario: A wide character is rewritten whole
- **WHEN** a row shows "中b" and the next frame shows "ab" in its place
- **THEN** the write starts at column 0 and contains "ab"

### Requirement: Resizing re-lays out the frame
When the terminal size changes between keys the next frame SHALL use the new size, every window of the tab page keeping its place in the layout.

#### Scenario: Terminal shrinks
- **WHEN** the terminal reports 24 rows and then 10 rows
- **THEN** the next frame has 10 rows and the status bar is on row 8

#### Scenario: Split windows after a resize
- **WHEN** a window is split vertically in an 80-column terminal and the terminal becomes 40 columns wide
- **THEN** the next frame still shows two windows side by side with one separator between them

## REMOVED Requirements

### Requirement: Status line content
**Reason**: Windows no longer have status lines of their own; one status bar shows the current window's buffer with more segments.
**Migration**: The `status-bar` capability states the bar's segments, their order, and the plugins' segments.

### Requirement: Every window has a status line
**Reason**: The status bar is global, as Neovim's `laststatus=3`; a window above another ends in a separator row.
**Migration**: The `status-bar` capability states the one bar; "Frame layout for several windows" states the separator rows.

### Requirement: The tab line takes the top row when there are several tab pages
**Reason**: The top row now lists the buffers and shows from two listed file buffers as well as from two tab pages.
**Migration**: The `buffer-tabs` capability states when the row shows and what it holds.
