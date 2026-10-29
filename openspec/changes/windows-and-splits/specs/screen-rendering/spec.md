# Spec Delta

## ADDED Requirements

### Requirement: Frame layout for several windows
The frame SHALL show every window of the current tab page in its own rectangle: a horizontal split stacks the windows with a status line under each, a vertical split places them side by side with one separator column between them in the status line highlight, showing the vertical bar character on every text row. Each window SHALL have its own line number gutter and text area, and rows past the end of its buffer SHALL show "~". The command line or message row SHALL stay the last row of the frame.

#### Scenario: Two stacked windows
- **WHEN** the lines ["one", "two", "three"] are shown in a window split horizontally in a 9-row, 14-column frame
- **THEN** rows 0 to 2 read "  1 one", "  2 two", "  3 three", row 3 is a status line, rows 4 to 6 read the same three lines, row 7 is a status line, and row 8 is the message row

#### Scenario: Two windows side by side
- **WHEN** the lines ["one", "two"] are shown in a window split vertically in a 6-row, 21-column frame
- **THEN** row 0 reads "  1 one   │  1 one", with the separator at column 10 carrying the status line highlight, row 4 holds both status lines, and row 5 is the message row

### Requirement: Every window has a status line
Each window SHALL have a status line under its text rows showing its buffer's path, or "[No Name]", " [+]" when the buffer is modified, and at its right end that window's cursor as "row,col" followed by the position, dropped when it would touch the path. The current window's status line SHALL use the status line highlight and the other windows' status lines the inactive status line highlight.

#### Scenario: Status lines of two windows
- **WHEN** "a.txt" is split horizontally and the bottom window's cursor is on (1, 0) while the top window is current at (0, 0)
- **THEN** the top status line starts with "a.txt" and ends with "1,1 All" in the status highlight, and the bottom one ends with "2,1 All" in the inactive status highlight

### Requirement: The cursor is placed in the current window
The frame cursor SHALL be placed inside the current window's rectangle, after its gutter, by display width, and each window SHALL scroll on its own to keep its cursor visible with scrolloff.

#### Scenario: Cursor in the bottom window
- **WHEN** a window is split horizontally in a 9-row frame and the bottom window is current with its cursor at (1, 0) and the number column shown
- **THEN** the frame cursor is at row 5, column 4

### Requirement: The tab line takes the top row when there are several tab pages
When more than one tab page exists, row 0 SHALL be the tab line and the windows SHALL be laid out from row 1; with one tab page the windows SHALL start at row 0.

#### Scenario: Two tab pages
- **WHEN** two tab pages exist, the first showing "a.txt" and current, the second "b.txt", in a 7-row frame
- **THEN** row 0 reads " 1 a.txt  2 b.txt " with " 1 a.txt " in the selected tab line highlight, " 2 b.txt " in the tab line highlight, the rest of the row in the tab line fill highlight, row 1 is the first text row, and row 5 is the status line

## MODIFIED Requirements

### Requirement: Frame layout for one window
A frame of R rows and C columns showing one tab page with one window SHALL use rows 0 to R-3 for the window, row R-2 for the status line, and row R-1 for the command line or message. Every window row SHALL start with a line number gutter, right-aligned numbers of width max(3, digits of the line count) followed by one space, when the number option is on, and no gutter otherwise. Rows past the end of the buffer SHALL show "~" in column 0.

#### Scenario: Three lines in a six-row frame
- **WHEN** the lines ["one", "two", "three"] are rendered in 6 rows and 12 columns with number on
- **THEN** rows 0 to 2 read "  1 one", "  2 two", "  3 three", row 3 reads "~", row 4 is the status line, and row 5 is the message row

#### Scenario: Number off
- **WHEN** the same lines are rendered with number off
- **THEN** row 0 reads "one" starting at column 0

#### Scenario: Wide gutter
- **WHEN** a buffer with 1000 lines is rendered with number on
- **THEN** the gutter is five columns wide and row 0 reads "   1 " followed by the text

### Requirement: Status line content
The status line of a window SHALL show the buffer path, or "[No Name]" when there is none, followed by " [+]" when the buffer is modified, and SHALL show at its right end that window's cursor as "row,col" using 1-based numbers followed by the window position "All", "Top", "Bot", or a percentage.

#### Scenario: Modified buffer
- **WHEN** the buffer for "a.txt" is modified and the cursor is at (1, 2) in a short buffer
- **THEN** the status line starts with "a.txt [+]" and ends with "2,3 All"

#### Scenario: Unnamed buffer
- **WHEN** a buffer with no path is rendered
- **THEN** the status line starts with "[No Name]"

### Requirement: Resizing re-lays out the frame
When the terminal size changes between keys the next frame SHALL use the new size, every window of the tab page keeping its place in the layout.

#### Scenario: Terminal shrinks
- **WHEN** the terminal reports 24 rows and then 10 rows
- **THEN** the next frame has 10 rows and the status line is on row 8

#### Scenario: Split windows after a resize
- **WHEN** a window is split vertically in an 80-column terminal and the terminal becomes 40 columns wide
- **THEN** the next frame still shows two windows side by side with one separator between them
