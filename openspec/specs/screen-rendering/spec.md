# screen-rendering Specification

## Purpose
Screen rendering turns the editor state into a frame of cells for one window and writes only what changed to the terminal. It fixes the layout of line numbers, text, status line, and message row, how the window scrolls to keep the cursor visible, and the terminal modes used while the editor runs.

## Requirements

### Requirement: Frame layout for one window
A frame of R rows and C columns SHALL use rows 0 to R-3 for the window, row R-2 for the status line, and row R-1 for the command line or message. Every window row SHALL start with a line number gutter, right-aligned numbers of width max(3, digits of the line count) followed by one space, when the number option is on, and no gutter otherwise. Rows past the end of the buffer SHALL show "~" in column 0.

#### Scenario: Three lines in a six-row frame
- **WHEN** the lines ["one", "two", "three"] are rendered in 6 rows and 12 columns with number on
- **THEN** rows 0 to 2 read "  1 one", "  2 two", "  3 three", row 3 reads "~", row 4 is the status line, and row 5 is the message row

#### Scenario: Number off
- **WHEN** the same lines are rendered with number off
- **THEN** row 0 reads "one" starting at column 0

#### Scenario: Wide gutter
- **WHEN** a buffer with 1000 lines is rendered with number on
- **THEN** the gutter is five columns wide and row 0 reads "   1 " followed by the text

### Requirement: Relative line numbers
When the relativenumber option is on, every row other than the cursor row SHALL show its distance from the cursor row; the cursor row SHALL show its absolute number when number is on and 0 otherwise.

#### Scenario: Relative numbers around the cursor
- **WHEN** three lines are rendered with number and relativenumber on and the cursor on row 1
- **THEN** the gutters read "  1 ", "  2 ", "  1 " for rows 0, 1, and 2 respectively, with row 1 showing the absolute number 2

### Requirement: Status line content
The status line SHALL show the buffer path, or "[No Name]" when there is none, followed by " [+]" when the buffer is modified, and SHALL show at its right end the cursor as "row,col" using 1-based numbers followed by the window position "All", "Top", "Bot", or a percentage.

#### Scenario: Modified buffer
- **WHEN** the buffer for "a.txt" is modified and the cursor is at (1, 2) in a short buffer
- **THEN** the status line starts with "a.txt [+]" and ends with "2,3 All"

#### Scenario: Unnamed buffer
- **WHEN** a buffer with no path is rendered
- **THEN** the status line starts with "[No Name]"

### Requirement: Message row content
The message row SHALL show, in priority order, the command line prefixed by ":" in command-line mode, the pending message if one was set by the last action, or "-- INSERT --" in insert mode, and SHALL be blank otherwise. A message SHALL stay until the next key is handled.

#### Scenario: Message replaces the mode indicator
- **WHEN** ":q" is run on a modified buffer
- **THEN** the message row reads "E37: No write since last change (add ! to override)"

#### Scenario: Message clears on the next key
- **WHEN** a message is showing and "l" is pressed
- **THEN** the message row is blank

### Requirement: The window scrolls to keep the cursor visible with scrolloff
The window SHALL scroll so the cursor row is on screen with at least scrolloff rows above and below it where the buffer allows, and SHALL scroll horizontally so the cursor column is visible when a line is wider than the text area.

#### Scenario: Moving down past the window
- **WHEN** a 20-line buffer is rendered in 8 rows with scrolloff 2 and the cursor moves to row 10
- **THEN** the first window row shows line 8 and the cursor is on the third window row from the bottom, with two rows below it

#### Scenario: Long line scrolls horizontally
- **WHEN** a line of 40 characters is rendered in 12 columns with number off and the cursor at column 30
- **THEN** the cursor is shown inside the frame and the row begins with a character from the line, not column 0

### Requirement: Tabs and wide characters take their display width
A tab character SHALL be displayed as spaces up to the next multiple of tabstop, and a wide character SHALL occupy two cells. The frame cursor SHALL be placed by display width.

#### Scenario: Tab expansion
- **WHEN** the line "a\tb" is rendered with tabstop 4 and number off
- **THEN** the row reads "a   b"

#### Scenario: Wide character
- **WHEN** the line "日x" is rendered with number off and the cursor is on "x"
- **THEN** the frame cursor column is 2

### Requirement: Cursor shape follows the mode
The frame SHALL carry a bar cursor shape in insert mode and a block shape otherwise, and the terminal SHALL be told the shape when it changes.

#### Scenario: Shape in insert mode
- **WHEN** "i" is pressed
- **THEN** the next frame has the bar cursor shape

### Requirement: Only changed cells are written to the terminal
Each frame SHALL be written to the terminal in one write. The first frame and any frame after a size change SHALL be written in full; later frames SHALL write only rows whose cells changed, plus the cursor position.

#### Scenario: Identical frame writes nothing but the cursor
- **WHEN** a frame is presented twice
- **THEN** the second write contains no cell text

#### Scenario: One changed row
- **WHEN** the next frame differs in row 2 only
- **THEN** the write contains row 2's text and no other row's text

### Requirement: Alternate screen on enter and leave
When the editor starts it SHALL switch the terminal to the alternate screen and clear it; when it ends it SHALL restore the block cursor and the main screen, in that order, so the shell's content is intact.

#### Scenario: Enter and leave sequences
- **WHEN** the editor enters and then leaves the screen
- **THEN** the terminal output begins with the alternate-screen enable sequence and ends with the alternate-screen disable sequence

### Requirement: Resizing re-lays out the frame
When the terminal size changes between keys the next frame SHALL use the new size.

#### Scenario: Terminal shrinks
- **WHEN** the terminal reports 24 rows and then 10 rows
- **THEN** the next frame has 10 rows and the status line is on row 8

### Requirement: Unprintable code points are shown as escape markers
A code point below 32 in a buffer line SHALL be displayed as a caret and the letter 64 above it, two cells wide. U+007F and the code points U+0080 to U+009F SHALL be displayed as "<" followed by two lowercase hexadecimal digits and ">", four cells wide. Both markers SHALL use the highlight of ordinary text, and the frame cursor on such a code point SHALL be placed on the first cell of its marker.

#### Scenario: Caret notation for a C0 control
- **WHEN** the line "a\x01b" is rendered with number off
- **THEN** the row reads "a^Ab"

#### Scenario: Delete and C1 controls as hexadecimal markers
- **WHEN** the lines "a\u007Fb", "a\u0080b", "a\u009Bb", and "a\u009Db" are each rendered with number off
- **THEN** the rows read "a<7f>b", "a<80>b", "a<9b>b", and "a<9d>b", and the cell after each marker is at column 5

#### Scenario: Cursor over and after a marker
- **WHEN** the line "a\u009Bb" is rendered with number off and the cursor on the second code point, and then on the third
- **THEN** the frame cursor column is 1, and then 5

### Requirement: No control code point reaches a frame cell or the terminal
No cell of a frame SHALL hold a code point below 32, U+007F, or U+0080 to U+009F. Text written to the frame that contains such a code point SHALL store U+FFFD in its cell instead. The bytes written to the terminal for a frame SHALL contain no C0 or C1 code point other than the escape sequences the screen presenter writes itself.

#### Scenario: A rendered line leaves no control code point in the frame
- **WHEN** a line containing U+007F, U+0080, U+009B, and U+009D is rendered
- **THEN** every cell of the frame holds a code point that is 32 or above, not U+007F, and outside U+0080 to U+009F

#### Scenario: Text written to the frame directly
- **WHEN** the text "a\u009Bb" is written to a frame row
- **THEN** the row's cells hold "a", U+FFFD, and "b"

#### Scenario: Terminal bytes for a frame with markers
- **WHEN** a frame drawn from a line containing U+009B and U+009D is presented
- **THEN** the bytes written contain the markers "<9b>" and "<9d>" and, outside the presenter's own escape sequences, no byte sequence encoding a code point from U+0080 to U+009F
