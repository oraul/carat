# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Appending to a blockwise register
Appending with an uppercase register name SHALL give a linewise entry when either part is linewise, and otherwise a blockwise entry with the rows of both parts when either part is blockwise.

#### Scenario: Charwise text appended to a block
- **WHEN** "<C-v>j\"ayl\"Ayl" is pressed at (0, 0) of ["ab", "cd"]
- **THEN** register "a" is blockwise with the rows "a", "c", and "b"
