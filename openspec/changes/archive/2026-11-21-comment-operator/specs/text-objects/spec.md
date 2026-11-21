## ADDED Requirements

### Requirement: Comment object
"gc" after an operator SHALL select, linewise, the adjacent commented lines around the cursor line, by the buffer's comment marker; a blank line ends the block. When the cursor line is not commented the operator SHALL do nothing.

#### Scenario: dgc deletes the comment block
- **WHEN** "dgc" is pressed on row 1 of ["a", "# b", "# c", "d"]
- **THEN** the lines are ["a", "d"]

#### Scenario: ygc yanks the comment block
- **WHEN** "ygc" is pressed on row 2 of ["# a", "# b", "c"]
- **THEN** the unnamed register holds the lines "# a" and "# b" and the buffer is unchanged

#### Scenario: dgc off a comment does nothing
- **WHEN** "dgc" is pressed on row 0 of ["a", "# b"]
- **THEN** the lines are ["a", "# b"]
