# insert-mode Specification

## Purpose
Insert mode puts typed characters into the buffer at the cursor. It covers the editing keys that are not bindings to actions elsewhere: newline, backspace, delete, tab, the arrow keys, and Escape back to normal mode.

## Requirements

### Requirement: Typed characters are inserted at the cursor
In insert mode a printable key that is not bound SHALL insert its character at the cursor, move the cursor one column right, and mark the buffer modified. Multi-byte characters count as one column.

#### Scenario: Typing a word
- **WHEN** "i" is pressed on the line "ab" at column 0 and then "x", "y" are typed
- **THEN** the line is "xyab", the cursor is at column 2, and the buffer is modified

#### Scenario: Typing a non-ASCII character
- **WHEN** "é" is typed in insert mode at column 1 of "ab"
- **THEN** the line is "aéb" and the cursor is at column 2

### Requirement: The cursor may stand after the last character
In insert mode the cursor SHALL be allowed at the column equal to the line length, and Left and Right SHALL move within 0 and that column.

#### Scenario: Right reaches the end of the line
- **WHEN** the line is "ab", the cursor is at column 1 in insert mode, and Right is pressed twice
- **THEN** the cursor is at column 2

### Requirement: Enter splits the line
Enter SHALL split the current line at the cursor and place the cursor at the start of the new line. When autoindent is on, the new line SHALL begin with the leading whitespace of the line it was split from, with the cursor after it.

#### Scenario: Split in the middle
- **WHEN** the cursor is at column 1 of "ab" in insert mode with autoindent off and Enter is pressed
- **THEN** the lines are ["a", "b"] and the cursor is at (1, 0)

#### Scenario: Autoindent copies the indent
- **WHEN** the cursor is at the end of "  ab" in insert mode with autoindent on and Enter is pressed
- **THEN** the lines are ["  ab", "  "] and the cursor is at (1, 2)

### Requirement: Backspace deletes before the cursor and joins lines
Backspace SHALL delete the character before the cursor. At column 0 of a line other than the first it SHALL join the line to the end of the previous one, placing the cursor at the join. At (0, 0) it SHALL do nothing.

#### Scenario: Backspace in a line
- **WHEN** the cursor is at column 2 of "abc" in insert mode and Backspace is pressed
- **THEN** the line is "ac" and the cursor is at column 1

#### Scenario: Backspace joins lines
- **WHEN** the lines are ["ab", "cd"], the cursor is at (1, 0) in insert mode, and Backspace is pressed
- **THEN** the lines are ["abcd"] and the cursor is at (0, 2)

#### Scenario: Backspace at the start of the buffer
- **WHEN** the cursor is at (0, 0) in insert mode and Backspace is pressed
- **THEN** nothing changes

### Requirement: Delete removes the character under the cursor
Delete SHALL remove the character at the cursor; at the end of a line other than the last it SHALL join the next line to it. At the end of the last line it SHALL do nothing.

#### Scenario: Delete in a line
- **WHEN** the cursor is at column 1 of "abc" in insert mode and Delete is pressed
- **THEN** the line is "ac" and the cursor stays at column 1

#### Scenario: Delete at the end of a line
- **WHEN** the lines are ["ab", "cd"], the cursor is at (0, 2), and Delete is pressed
- **THEN** the lines are ["abcd"]

### Requirement: Tab inserts according to expandtab and tabstop
Tab SHALL insert spaces up to the next multiple of tabstop when expandtab is on, and one tab character otherwise.

#### Scenario: Expandtab on
- **WHEN** the cursor is at column 1 of "a" with tabstop 4 and expandtab on, and Tab is pressed
- **THEN** the line is "a   " and the cursor is at column 4

#### Scenario: Expandtab off
- **WHEN** expandtab is off and Tab is pressed at column 0 of an empty line
- **THEN** the line is "\t" and the cursor is at column 1

### Requirement: Escape returns to normal mode one column left
Escape SHALL return to normal mode and move the cursor one column left unless it is at column 0, so the cursor rests on the last inserted character.

#### Scenario: Escape after typing
- **WHEN** "i", "a", "b", Escape are pressed on an empty line
- **THEN** the mode is normal and the cursor is at column 1

#### Scenario: Escape at column 0
- **WHEN** Escape is pressed in insert mode at column 0
- **THEN** the mode is normal and the cursor is at column 0

### Requirement: The mode indicator shows insert mode
While in insert mode the message row SHALL show "-- INSERT --", and it SHALL be cleared on returning to normal mode.

#### Scenario: Indicator on and off
- **WHEN** "i" is pressed and then Escape
- **THEN** the message row shows "-- INSERT --" after "i" and is empty after Escape
