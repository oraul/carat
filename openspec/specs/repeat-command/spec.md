# repeat-command Specification

## Purpose
Lets the user repeat the last change with the dot command, as Neovim's ".", including the text typed in its insert session and a visual region of the same size.

## Requirements

### Requirement: Dot repeats the last change
Pressing "." SHALL repeat the last change at the cursor: an operator with its motion or text object, a standalone edit such as "x", "s", "S", "C", "D", "J", "p", "P", "r", or "~", or an insert command with the text typed until Escape. With no change made yet it SHALL do nothing.

#### Scenario: Repeat an operator with a motion
- **WHEN** "dw" is pressed at (0, 0) of ["one two three"], then "."
- **THEN** the line is "three"

#### Scenario: Repeat a standalone edit
- **WHEN** "x" is pressed at (0, 0) of ["abc"], then "."
- **THEN** the line is "c"

#### Scenario: Repeat a change with its text
- **WHEN** "cw", "X", Escape are pressed at (0, 0) of ["one two"], then "w", then "."
- **THEN** the line is "X X"

#### Scenario: Repeat an insert command
- **WHEN** "A", "!", Escape are pressed on ["a", "b"], then "j", then "."
- **THEN** the lines are ["a!", "b!"]

#### Scenario: Repeat an opened line with Enter typed
- **WHEN** "o", "x", Enter, "y", Escape are pressed on ["a"], then "."
- **THEN** the lines are ["a", "x", "y", "x", "y"]

#### Scenario: Nothing to repeat
- **WHEN** "." is pressed before any change
- **THEN** the lines and the cursor are unchanged

### Requirement: Dot does not repeat what is not a change
Motions, yanks, undo, redo, "U", and ex commands SHALL leave the last change as it was, so "." after them repeats the change before.

#### Scenario: A yank between
- **WHEN** "x" is pressed at (0, 0) of ["abcd"], then "yl", then "."
- **THEN** the line is "cd"

#### Scenario: Undo between
- **WHEN** "x" is pressed at (0, 0) of ["abcd"], then "u", then "."
- **THEN** the line is "bcd"

#### Scenario: An ex command between
- **WHEN** "x" is pressed at (0, 0) of ["abcd"], then ":w" is run, then "."
- **THEN** the line is "cd"

### Requirement: A count on dot replaces the change's count
A count typed before "." SHALL replace the count of the repeated change, for this and later repeats; without one the change's own count SHALL be used.

#### Scenario: The original count
- **WHEN** "2x" is pressed at (0, 0) of ["abcdefg"], then "."
- **THEN** the line is "efg"

#### Scenario: A new count
- **WHEN** "2x" is pressed at (0, 0) of ["abcdefghij"], then "3.", then "."
- **THEN** the line is "ij"

### Requirement: Dot is one undo state
A repeated change SHALL be one undo state, its inserted text included.

#### Scenario: Undo a repeat
- **WHEN** "cw", "X", Escape are pressed at (0, 0) of ["one two"], then "w", ".", then "u"
- **THEN** the line is "X two"

### Requirement: Dot reuses the register, counting up numbered ones
A repeated change SHALL use the register its command named; when that is "1" to "8", each repeat SHALL use the next numbered register.

#### Scenario: A named register
- **WHEN** the quote key, "a", "d", "w" are pressed at (0, 0) of ["one two three"], then "."
- **THEN** register a holds "two "

#### Scenario: Stepping through deletes
- **WHEN** "dd" is pressed three times on ["a", "b", "c", "x"], then the quote key, "1", "p", then ".", then "."
- **THEN** the lines are ["x", "c", "b", "a"]

### Requirement: Dot repeats a visual operator over a region of the same size
A change made by an operator on a visual selection SHALL be repeated from the cursor over the same number of lines, and the same number of characters on one line, the same end column on several lines, or the same display columns for a block.

#### Scenario: Characters on one line
- **WHEN** "vld" is pressed at (0, 0) of ["abcdef"], then "."
- **THEN** the line is "ef"

#### Scenario: Whole lines
- **WHEN** "Vj>" is pressed on row 0 of ["a", "b", "c", "d"], then "jj", then "."
- **THEN** the lines are ["  a", "  b", "  c", "  d"] with a shiftwidth of 2

#### Scenario: A block
- **WHEN** "<C-v>jd" is pressed at (0, 0) of ["abc", "def"], then "."
- **THEN** the lines are ["c", "f"]

#### Scenario: A block insert
- **WHEN** "<C-v>jI", "-", Escape are pressed at (0, 0) of ["ab", "cd"], then "l", then "."
- **THEN** the lines are ["--ab", "--cd"]
