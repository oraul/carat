# Spec Delta

## Purpose

Normal mode is where the editor starts and where keys move the cursor and switch modes instead of inserting text. This capability covers the foundation motions and the entries into insert mode; counts, operators, and the remaining motions arrive with the command grammar.

## ADDED Requirements

### Requirement: The editor starts in normal mode with the cursor at the first line
After a file is opened the editor SHALL be in normal mode with the cursor on row 0, column 0.

#### Scenario: Fresh start
- **WHEN** the editor opens a file with three lines
- **THEN** the mode is normal and the cursor is at (0, 0)

### Requirement: Left and right motions stay within the line
In normal mode "h" and Left SHALL move the cursor one column left and "l" and Right one column right, never past column 0 or past the last character of the line. On an empty line the cursor SHALL stay at column 0.

#### Scenario: Right at line end does nothing
- **WHEN** the cursor is on the last character of "abc" and "l" is pressed
- **THEN** the cursor stays at column 2

#### Scenario: Left at line start does nothing
- **WHEN** the cursor is at column 0 and "h" is pressed
- **THEN** the cursor stays at column 0

#### Scenario: Right moves one column
- **WHEN** the cursor is at column 0 of "abc" and "l" is pressed twice
- **THEN** the cursor is at column 2

### Requirement: Up and down motions keep the desired column
"j" and Down SHALL move the cursor one row down and "k" and Up one row up, never past the first or last line. The cursor SHALL remember the column it aimed for, so moving through a shorter line and back returns to that column, and SHALL be clamped to the last character of each line it lands on.

#### Scenario: Shorter line clamps the column
- **WHEN** the cursor is at (0, 4) in the lines ["abcdef", "xy", "123456"] and "j" is pressed
- **THEN** the cursor is at (1, 1)

#### Scenario: Desired column returns
- **WHEN** from (1, 1) in those lines, reached from column 4, "j" is pressed
- **THEN** the cursor is at (2, 4)

#### Scenario: Horizontal motion resets the desired column
- **WHEN** the cursor is at (0, 4), "h" is pressed, then "j" and "j"
- **THEN** the cursor is at (2, 3)

#### Scenario: Down at the last line does nothing
- **WHEN** the cursor is on the last line and "j" is pressed
- **THEN** the cursor row is unchanged

### Requirement: Line and buffer motions
"0" SHALL move to column 0, "^" to the first non-blank character, "$" to the last character, "gg" to the first line, and "G" to the last line. "$" SHALL set the desired column to the line end so that following vertical motions stay at each line's end.

#### Scenario: First non-blank
- **WHEN** the line is "   abc" and "^" is pressed
- **THEN** the cursor column is 3

#### Scenario: Dollar then down sticks to line ends
- **WHEN** the lines are ["abc", "abcdef"], the cursor is at (0, 0), and "$" then "j" are pressed
- **THEN** the cursor is at (1, 5)

#### Scenario: gg and G
- **WHEN** the cursor is on row 1 of three lines and "G" is pressed, then "gg"
- **THEN** the cursor is on row 2 after "G" and on row 0 after "gg"

### Requirement: Entering insert mode at Vim's positions
"i" SHALL enter insert mode before the cursor, "a" after it, "I" at the first non-blank character, "A" after the last character, "o" on a new line below the current one, and "O" on a new line above. "o" and "O" SHALL mark the buffer modified.

#### Scenario: a on a non-empty line
- **WHEN** the cursor is at (0, 0) of "ab" and "a" is pressed
- **THEN** the mode is insert and the cursor is at (0, 1)

#### Scenario: A moves past the end
- **WHEN** the cursor is at (0, 0) of "ab" and "A" is pressed
- **THEN** the mode is insert and the cursor is at (0, 2)

#### Scenario: o opens a line below
- **WHEN** the cursor is on row 0 of ["ab", "cd"] and "o" is pressed
- **THEN** the lines are ["ab", "", "cd"], the mode is insert, and the cursor is at (1, 0)

#### Scenario: O opens a line above
- **WHEN** the cursor is on row 1 of ["ab", "cd"] and "O" is pressed
- **THEN** the lines are ["ab", "", "cd"] and the cursor is at (1, 0)

#### Scenario: I goes to the first non-blank
- **WHEN** the line is "  ab", the cursor is at column 3, and "I" is pressed
- **THEN** the mode is insert and the cursor is at column 2

### Requirement: Ctrl-C shows the quit hint
Pressing Ctrl-C in normal mode SHALL show the message "Type  :q!  and press <Enter> to abandon all changes and exit Carat" and change nothing else.

#### Scenario: Ctrl-C in normal mode
- **WHEN** Ctrl-C is pressed in normal mode
- **THEN** the message row shows the quit hint and the buffer, cursor, and mode are unchanged

### Requirement: Actions from later roadmap items report themselves
Pressing a key bound in the default configuration to an action this change does not implement SHALL show the message "Not implemented: " followed by the action name, and change nothing else.

#### Scenario: dd before operators exist
- **WHEN** "d" then "d" are pressed in normal mode
- **THEN** the message is "Not implemented: operator.delete_line" and the buffer is unchanged
