# screen-rendering Specification

## Purpose
Screen rendering turns the editor state into a frame of cells for one window and writes only what changed to the terminal. It fixes the layout of line numbers, text, status line, and message row, how the window scrolls to keep the cursor visible, and the terminal modes used while the editor runs.

## Requirements

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

### Requirement: Relative line numbers
When the relativenumber option is on, every row other than the cursor row SHALL show its distance from the cursor row; the cursor row SHALL show its absolute number when number is on and 0 otherwise.

#### Scenario: Relative numbers around the cursor
- **WHEN** three lines are rendered with number and relativenumber on and the cursor on row 1
- **THEN** the gutters read "  1 ", "  2 ", "  1 " for rows 0, 1, and 2 respectively, with row 1 showing the absolute number 2

### Requirement: Message row content
The message row SHALL show, in priority order, the command line prefixed by ":" in command-line mode, or by a plugin's prompt text in place of ":" while a plugin prompt is open, the pending message if one was set by the last action, or "-- INSERT --" in insert mode, "-- VISUAL --", "-- VISUAL LINE --", or "-- VISUAL BLOCK --" in the visual modes, and SHALL be blank otherwise. A message SHALL stay until the next key is handled. The cursor SHALL be placed after the command line text.

#### Scenario: Message replaces the mode indicator
- **WHEN** ":q" is run on a modified buffer
- **THEN** the message row reads "E37: No write since last change (add ! to override)"

#### Scenario: Message clears on the next key
- **WHEN** a message is showing and "l" is pressed
- **THEN** the message row is blank

#### Scenario: Prompt in place of the colon
- **WHEN** a plugin prompts "Rename to: " with the initial value "a.rb"
- **THEN** the message row reads "Rename to: a.rb" and the cursor is in column 15 of it

#### Scenario: Visual block indicator
- **WHEN** "<C-v>" is pressed in normal mode
- **THEN** the message row reads "-- VISUAL BLOCK --"

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
The frame SHALL carry a bar cursor shape in insert mode, an underline shape in replace mode, and a block shape in every other mode (normal, the visual modes, operator-pending, and command-line), and the terminal SHALL be told the shape when it changes: a steady bar, a steady underline, or a steady block.

#### Scenario: Shape in insert mode
- **WHEN** "i" is pressed
- **THEN** the next frame has the bar cursor shape

#### Scenario: Shape per mode
- **WHEN** a frame is drawn in normal, insert, replace, visual, operator-pending, and command-line mode
- **THEN** its cursor shape is a block, a bar, an underline, a block, a block, and a block

#### Scenario: Underline sent to the terminal
- **WHEN** a frame with the underline shape follows one with the block shape
- **THEN** the write sets the steady underline cursor, and a later frame with the same shape does not set it again

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

### Requirement: Alternate screen on enter and leave
When the editor starts it SHALL switch the terminal to the alternate screen and clear it; when it ends it SHALL reset the colors, restore the terminal's own cursor shape, show the cursor, and restore the main screen, in that order, so the shell's content and cursor are as they were.

#### Scenario: Enter and leave sequences
- **WHEN** the editor enters and then leaves the screen
- **THEN** the terminal output begins with the alternate-screen enable sequence and ends with the reset of the cursor shape to the terminal's default, the cursor shown, and the alternate-screen disable sequence

### Requirement: Resizing re-lays out the frame
When the terminal size changes between keys the next frame SHALL use the new size, every window of the tab page keeping its place in the layout.

#### Scenario: Terminal shrinks
- **WHEN** the terminal reports 24 rows and then 10 rows
- **THEN** the next frame has 10 rows and the status bar is on row 8

#### Scenario: Split windows after a resize
- **WHEN** a window is split vertically in an 80-column terminal and the terminal becomes 40 columns wide
- **THEN** the next frame still shows two windows side by side with one separator between them

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

### Requirement: Frame layout for several windows
The frame SHALL show every window of the current tab page in its own rectangle: a horizontal split stacks the windows, each window above another ending in a separator row of "─" across its width; a vertical split places them side by side with one separator column of "│" between them, down to the status bar. Every separator SHALL be in `WinSeparator`. Each window SHALL have its own gutter and text area, rows past the end of its buffer SHALL show "~", and the message row SHALL stay the last row.

#### Scenario: Two stacked windows
- **WHEN** the lines ["one", "two", "three"] are shown in a window split horizontally in a 9-row, 14-column frame
- **THEN** rows 0 to 2 read "  1 one", "  2 two", "  3 three", row 3 is a separator row of "─" in `WinSeparator`, rows 4 to 6 read the same three lines, row 7 is the status bar, and row 8 is the message row

#### Scenario: Two windows side by side
- **WHEN** the lines ["one", "two"] are shown in a window split vertically in a 6-row, 21-column frame
- **THEN** row 0 reads "  1 one   │  1 one", with the separator at column 10 in `WinSeparator`, row 4 is the status bar across all 21 columns, and row 5 is the message row

### Requirement: The cursor is placed in the current window
The frame cursor SHALL be placed inside the current window's rectangle, after its gutter, by display width, and each window SHALL scroll on its own to keep its cursor visible with scrolloff.

#### Scenario: Cursor in the bottom window
- **WHEN** a window is split horizontally in a 9-row frame and the bottom window is current with its cursor at (1, 0) and the number column shown
- **THEN** the frame cursor is at row 5, column 4

### Requirement: Signs take a column before the line numbers
A buffer with at least one sign SHALL be drawn with a sign column two cells wide at the left of its windows, before the line numbers, holding each sign's glyph on its row and blanks elsewhere; a buffer with no signs SHALL have no sign column.

#### Scenario: One sign
- **WHEN** the "error" sign of the ascii set is placed on row 1 of a three-line buffer with line numbers on
- **THEN** row 1 of the frame starts with "X   2 " and row 0 starts with "    1 "

#### Scenario: No signs
- **WHEN** the buffer has no signs
- **THEN** row 0 starts with "  1 "

### Requirement: The selection is drawn with the Visual highlight
In a visual mode the current window SHALL draw every selected character with the Visual highlight group, and the cell after a line's last character when its line break is selected; the cell under the cursor SHALL keep its own highlight so the cursor shows on top. Other windows, including those showing the same buffer, SHALL draw no selection.

#### Scenario: Charwise selection
- **WHEN** "vl" is pressed at (0, 0) of "abc"
- **THEN** the cell of "a" uses the Visual highlight, the cell of "b" under the cursor does not, and the cell of "c" does not

#### Scenario: Linewise selection includes the line end
- **WHEN** "V" is pressed at (0, 0) of "ab"
- **THEN** the cells of "b" and of the line end after it use the Visual highlight

#### Scenario: Two windows on one buffer
- **WHEN** ":split" then "Vj" are pressed
- **THEN** only the current window draws the Visual highlight

### Requirement: A block is drawn on display columns
A blockwise selection SHALL be drawn over the same display columns on every row of the block, from the leftmost to the rightmost cell of the anchor's and the cursor's characters, so a tab or a wide character on its edge is covered cell by cell; after "$" it SHALL reach every row's end.

#### Scenario: Block over a tab
- **WHEN** "<C-v>ljj" is pressed at (0, 1) of ["abcd", "a\tb", "abcd"] with tabstop 4
- **THEN** display columns 1 and 2 of the tab's row use the Visual highlight and its column 3 does not

#### Scenario: Block over a wide character
- **WHEN** "<C-v>j" is pressed at (0, 1) of ["a中b", "abcd"]
- **THEN** the block covers display columns 1 and 2 on both rows

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

### Requirement: A message of several lines takes the bottom rows
A message of several lines SHALL be drawn over the rows above the message row, its last lines when it is taller than the screen, with "Press ENTER or type command to continue" in the message row and the cursor after it. Enter or Space SHALL dismiss it; any other key SHALL dismiss it and be handled as usual.

#### Scenario: The registers listing
- **WHEN** ":registers" is run after "yy" on ["one"] in a 10-row screen
- **THEN** rows 5 to 8 show the four lines of the listing, row 9 reads "Press ENTER or type command to continue", and the windows are drawn above them

#### Scenario: Enter dismisses
- **WHEN** the listing shows and Enter is pressed
- **THEN** the windows are drawn again, the message row is blank, and the cursor has not moved

#### Scenario: Another key is handled
- **WHEN** the listing shows and "x" is pressed
- **THEN** the listing is gone and the character under the cursor is deleted

### Requirement: A byte outside a well-formed UTF-8 sequence is one replacement cell
Text SHALL be decoded as UTF-8 per RFC 3629, and every byte outside a well-formed sequence (an overlong form, a surrogate, a sequence above U+10FFFF, a truncated sequence, or a lone continuation byte) SHALL be one character of its own, displayed as one U+FFFD cell. No code point above U+10FFFF or from U+D800 to U+DFFF SHALL reach the terminal.

#### Scenario: Hostile sequences decode to replacement characters
- **WHEN** the bytes C0 AF, E0 80 80, ED A0 80, F0 80 80 80, F4 90 80 80, F5 80, E4 B8, and 80 are each decoded
- **THEN** each byte is one character of U+FFFD, one cell wide

#### Scenario: Well-formed sequences at the edges
- **WHEN** the bytes C2 80, E0 A0 80, ED 9F BF, EE 80 80, F0 90 80 80, and F4 8F BF BF are each decoded
- **THEN** each is one character, U+0080, U+0800, U+D7FF, U+E000, U+10000, and U+10FFFF

#### Scenario: A cell beyond Unicode is written as the replacement character
- **WHEN** a frame cell holds the code 0x110000 or 0xD800 and the frame is presented
- **THEN** the bytes written hold U+FFFD for that cell and the presenter raises nothing

### Requirement: The current line is highlighted in the current window
When the cursorline option is on, the row of the current window that shows the cursor's line SHALL be drawn over the `CursorLine` background from the end of the gutter to the window's right edge, each cell keeping its foreground and attributes and a group with its own background keeping it, and its number SHALL be drawn in `CursorLineNr`. Other windows SHALL show no cursor line.

#### Scenario: The cursor line of the current window
- **WHEN** a buffer of three lines is shown with cursorline on and the cursor on line 2
- **THEN** every text cell of the second window row, the blanks after the text included, has the cursor-line background, and the other rows have none

#### Scenario: Only the current window
- **WHEN** two windows show the buffer with cursorline on and the cursor on line 1 of each
- **THEN** only the current window's first row has the cursor-line background

#### Scenario: The highlight follows the cursor
- **WHEN** "j" is pressed with cursorline on and the cursor on line 1
- **THEN** the second row has the cursor-line background and the first row is drawn as without it

#### Scenario: The number on the cursor line
- **WHEN** a buffer is shown with number and cursorline on
- **THEN** the cursor line's number is drawn in `CursorLineNr` and the other numbers in `LineNr`

### Requirement: The cursorline option
The cursorline option SHALL be read from `option.cursorline` lines of the configuration, taking true or false, and set by `:set cursorline` and `:set cul` with Vim's boolean forms `no`, `inv`, a trailing `!`, and a trailing `?`.

#### Scenario: Off
- **WHEN** ":set nocul" is entered
- **THEN** no row has the cursor-line background and ":set cul?" shows "nocursorline"

#### Scenario: A configuration value of the wrong kind
- **WHEN** the project file's first line is "option.cursorline yes"
- **THEN** ".caratrc:1: option.cursorline takes true or false" is reported and the option keeps its value
