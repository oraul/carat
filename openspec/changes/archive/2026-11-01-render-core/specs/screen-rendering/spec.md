## MODIFIED Requirements

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
- **THEN** the write contains the changed cursor column of the status line and no text of the buffer

#### Scenario: A wide character is rewritten whole
- **WHEN** a row shows "中b" and the next frame shows "ab" in its place
- **THEN** the write starts at column 0 and contains "ab"

## ADDED Requirements

### Requirement: A vertical scroll is sent as a scroll region
When a window that spans the full width of the terminal scrolls vertically by fewer rows than its height between two presented frames, the write SHALL set a scroll region over the window's text rows, scroll it up or down by that many rows, reset the scroll region, and then write only the rows that came into view and the cells that otherwise changed. A window narrower than the terminal SHALL be redrawn by rows instead.

#### Scenario: Scrolling down one line
- **WHEN** the cursor is on the last text row of a full-width window with scrolloff 0 over a longer buffer and "j" is pressed
- **THEN** the write sets the scroll region to the window's text rows, scrolls it up by one row, resets the region, writes the line that came into view at the bottom, and writes fewer than 500 bytes on a 200-column terminal

#### Scenario: Scrolling up one line
- **WHEN** the cursor is on the first text row of a full-width window scrolled past its first line with scrolloff 0 and "k" is pressed
- **THEN** the write sets the scroll region to the window's text rows, scrolls it down by one row, resets the region, and writes the line that came into view at the top

#### Scenario: A window beside another scrolls by rows
- **WHEN** the window is split vertically and the current window scrolls down one line
- **THEN** the write contains no scroll region and rewrites the changed rows of that window

#### Scenario: The first frame after a resize
- **WHEN** the terminal is resized and the window scrolls in the same frame
- **THEN** the frame is written in full without a scroll region
