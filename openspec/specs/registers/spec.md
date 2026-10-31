# registers Specification

## Purpose
Registers hold text that deletes and yanks store and that puts read back, each entry with its kind so linewise text pastes as lines. This capability covers the unnamed register and the named registers with uppercase append.

## Requirements

### Requirement: Deletes and yanks write the unnamed register
Every delete, change, and yank SHALL store the removed or copied text in the unnamed register with its kind, charwise, linewise, or blockwise, replacing what was there.

#### Scenario: dd then p
- **WHEN** "dd" is pressed on row 0 of ["a", "b"], then "p"
- **THEN** the lines are ["b", "a"]

#### Scenario: x then P
- **WHEN** "x" is pressed at (0, 0) of "ab", then "P"
- **THEN** the line is "ab" and the cursor is at (0, 0)

#### Scenario: The latest write wins
- **WHEN** "yw" is pressed at (0, 0) of "one two", then "x", then "$p"
- **THEN** the line is "ne twoo"

#### Scenario: A block yank is blockwise
- **WHEN** "<C-v>jy" is pressed at (0, 0) of ["ab", "cd"]
- **THEN** the unnamed register is blockwise with the rows "a" and "c"

### Requirement: A named register receives the text as well
When the command names a register "a" to "z", the text SHALL be stored in that register and in the unnamed register. A put naming a lowercase or uppercase letter SHALL read that letter's register.

#### Scenario: Yank into a and put from a
- **WHEN** the quote key, "a", "y", "w" are pressed at (0, 0) of "ab cd", then "w", then the quote key, "a", "p"
- **THEN** the line is "ab cab d"

#### Scenario: The unnamed register follows a named yank
- **WHEN** the quote key, "a", "y", "y" are pressed on ["a", "b"], then "p"
- **THEN** the lines are ["a", "a", "b"]

#### Scenario: Uppercase name reads the lowercase register
- **WHEN** the quote key, "a", "y", "y" are pressed on ["a"], then the quote key, "A", "p"
- **THEN** the lines are ["a", "a"]

### Requirement: An uppercase register name appends
When the command names a register "A" to "Z", the text SHALL be appended to the lowercase register's content: charwise text is joined to charwise text, and when either part is linewise the result is linewise with the parts as lines. The unnamed register SHALL hold only the new text.

#### Scenario: Append lines
- **WHEN** the quote key, "a", "y", "y" are pressed on row 0 of ["a", "b"], then "j", the quote key, "A", "y", "y", then the quote key, "a", "p"
- **THEN** the lines are ["a", "b", "a", "b"]

#### Scenario: Append characters
- **WHEN** the quote key, "a", "y", "l" are pressed at (0, 0) of "ab", then "l", the quote key, "A", "y", "l", then the quote key, "a", "P"
- **THEN** the line is "aabb"

#### Scenario: Mixed kinds become linewise
- **WHEN** the quote key, "a", "y", "l" are pressed at (0, 0) of ["ab", "c"], then "j", the quote key, "A", "y", "y", then "k", the quote key, "a", "p"
- **THEN** the lines are ["ab", "a", "c", "c"]

### Requirement: An empty register cannot be put
A put from a register that holds nothing SHALL show "E353: Nothing in register" followed by the register name and change nothing.

#### Scenario: Empty named register
- **WHEN** the quote key, "b", "p" are pressed before register b was written
- **THEN** the message row shows "E353: Nothing in register b"

### Requirement: Appending to a blockwise register
Appending with an uppercase register name SHALL give a linewise entry when either part is linewise, and otherwise a blockwise entry with the rows of both parts when either part is blockwise.

#### Scenario: Charwise text appended to a block
- **WHEN** "<C-v>j\"ayl\"Ayl" is pressed at (0, 0) of ["ab", "cd"]
- **THEN** register "a" is blockwise with the rows "a", "c", and "b"
