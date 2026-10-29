# Spec Delta

## MODIFIED Requirements

### Requirement: Status line content
The status line of a window SHALL show the buffer path, or the title of a scratch buffer, or "[No Name]" when there is neither, followed by " [+]" when the buffer is modified, then on the current window's status line the status segments of the plugins in registration order separated by one space after two spaces, and SHALL show at its right end that window's cursor as "row,col" using 1-based numbers followed by the window position "All", "Top", "Bot", or a percentage.

#### Scenario: Modified buffer
- **WHEN** the buffer for "a.txt" is modified and the cursor is at (1, 2) in a short buffer
- **THEN** the status line starts with "a.txt [+]" and ends with "2,3 All"

#### Scenario: Unnamed buffer
- **WHEN** a buffer with no path is rendered
- **THEN** the status line starts with "[No Name]"

#### Scenario: Scratch buffer
- **WHEN** a scratch buffer titled "list" is rendered
- **THEN** its status line starts with "list"

#### Scenario: Status segment
- **WHEN** the hello plugin has set the segment "hello 1" and the current window shows "a.txt"
- **THEN** the current window's status line starts with "a.txt  hello 1" and another window's status line does not show the segment

## ADDED Requirements

### Requirement: Signs take a column before the line numbers
A buffer with at least one sign SHALL be drawn with a sign column two cells wide at the left of its windows, before the line numbers, holding each sign's glyph on its row and blanks elsewhere; a buffer with no signs SHALL have no sign column.

#### Scenario: One sign
- **WHEN** the "error" sign of the ascii set is placed on row 1 of a three-line buffer with line numbers on
- **THEN** row 1 of the frame starts with "X   2 " and row 0 starts with "    1 "

#### Scenario: No signs
- **WHEN** the buffer has no signs
- **THEN** row 0 starts with "  1 "
