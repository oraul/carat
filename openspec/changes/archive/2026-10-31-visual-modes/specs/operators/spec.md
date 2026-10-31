# Spec Delta

## ADDED Requirements

### Requirement: Putting a blockwise register
"p" and "P" in normal mode with a blockwise register SHALL insert its rows count times as a block, starting on the cursor row at the display column after the cursor's character for "p" or at the cursor's for "P", padding rows that are too short with spaces and adding rows past the end of the buffer; the cursor goes to the block's first character.

#### Scenario: p puts a block after the cursor
- **WHEN** "<C-v>jly" is pressed at (0, 0) of ["abc", "def"], then "$p"
- **THEN** the lines are ["abcab", "defde"] and the cursor is at (0, 3)

#### Scenario: P pads a short row
- **WHEN** a block of the rows "x" and "y" is put with "P" at (0, 2) of ["abc", "d"]
- **THEN** the lines are ["abxc", "d y"]

#### Scenario: Rows past the end of the buffer
- **WHEN** a block of the rows "x" and "y" is put with "p" at (0, 0) of ["a"]
- **THEN** the lines are ["ax", " y"]
