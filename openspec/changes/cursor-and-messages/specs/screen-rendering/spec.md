## MODIFIED Requirements

### Requirement: The current line is highlighted in the current window
When the cursorline option is on, the row of the current window that shows the cursor's line SHALL be drawn over the `CursorLine` background from the window's left edge, the sign column, number, and gap included, to the window's right edge, each cell keeping its foreground and attributes and a group with its own background (the selection) keeping it, and its number SHALL be drawn in `CursorLineNr`. Other windows SHALL show no cursor line.

#### Scenario: The cursor line of the current window
- **WHEN** a buffer of three lines is shown with cursorline on and the cursor on line 2
- **THEN** every cell of the second window row from column 0, the number and the blanks after the text included, has the cursor-line background, and the other rows have none

#### Scenario: Only the current window
- **WHEN** two windows show the buffer with cursorline on and the cursor on line 1 of each
- **THEN** only the current window's first row has the cursor-line background

#### Scenario: The highlight follows the cursor
- **WHEN** "j" is pressed with cursorline on and the cursor on line 1
- **THEN** the second row has the cursor-line background and the first row is drawn as without it

#### Scenario: The number on the cursor line
- **WHEN** a buffer is shown with number and cursorline on
- **THEN** the cursor line's number is drawn in `CursorLineNr` over the cursor-line background and the other numbers in `LineNr`

#### Scenario: The gutter on the cursor line
- **WHEN** a buffer is shown with number and cursorline on and the cursor on line 2
- **THEN** the cells of the second row from column 0 to the end of the gutter have the cursor-line background

#### Scenario: Every fifth relative number
- **WHEN** a buffer is shown with relativenumber on
- **THEN** the numbers 5, 10, and the like away from the cursor are drawn in `LineNrFifth`, the other relative numbers in `LineNr`, and with relativenumber off every number but the cursor line's is in `LineNr`

### Requirement: Cursor shape follows the mode
The frame SHALL carry a bar cursor shape in insert mode and on the command line, which every query prompt shares, an underline shape in replace mode, and a block shape in every other mode (normal, the visual modes, and operator-pending), and the terminal SHALL be told the shape when it changes: a steady bar, a steady underline, or a steady block.

#### Scenario: Shape in insert mode
- **WHEN** "i" is pressed
- **THEN** the next frame has the bar cursor shape

#### Scenario: Shape per mode
- **WHEN** a frame is drawn in normal, insert, replace, visual, operator-pending, and command-line mode
- **THEN** its cursor shape is a block, a bar, an underline, a block, a block, and a bar

#### Scenario: Underline sent to the terminal
- **WHEN** a frame with the underline shape follows one with the block shape
- **THEN** the write sets the steady underline cursor, and a later frame with the same shape does not set it again
