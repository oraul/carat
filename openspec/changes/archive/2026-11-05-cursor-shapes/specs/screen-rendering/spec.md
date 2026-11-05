## MODIFIED Requirements

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

### Requirement: Alternate screen on enter and leave
When the editor starts it SHALL switch the terminal to the alternate screen and clear it; when it ends it SHALL reset the colors, restore the terminal's own cursor shape, show the cursor, and restore the main screen, in that order, so the shell's content and cursor are as they were.

#### Scenario: Enter and leave sequences
- **WHEN** the editor enters and then leaves the screen
- **THEN** the terminal output begins with the alternate-screen enable sequence and ends with the reset of the cursor shape to the terminal's default, the cursor shown, and the alternate-screen disable sequence

## ADDED Requirements

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
