## ADDED Requirements

### Requirement: :m moves the lines of a range below an address
`:[range]m[ove] {address}` SHALL move the lines of the range, the cursor line without one, below the line the address names, `0` meaning above the first line, as one undo step. The cursor SHALL go to the last moved line. Above two lines the message SHALL be "N lines moved". A target just above or below the range SHALL change nothing.

#### Scenario: Move a line to the top
- **WHEN** ":2m0" is run on the lines "a", "b", "c"
- **THEN** the lines are "b", "a", "c" and the cursor is on row 1

#### Scenario: Move a range to the end
- **WHEN** ":1,3m$" is run on the lines "a", "b", "c", "d"
- **THEN** the lines are "d", "a", "b", "c", the cursor is on row 4, and the message is "3 lines moved"

#### Scenario: Move is one undo step
- **WHEN** ":2m0" is run on the lines "a", "b", "c" and then "u" is typed
- **THEN** the lines are "a", "b", "c"

#### Scenario: Move each marked line to the top
- **WHEN** ":g/x/m0" is run on the lines "x1", "a", "x2", "b", "x3"
- **THEN** the lines are "x3", "x2", "x1", "a", "b"

### Requirement: :co and :t copy the lines of a range below an address
`:[range]co[py] {address}` and `:[range]t {address}` SHALL put a copy of the lines of the range, the cursor line without one, below the line the address names, `0` meaning above the first line, as one undo step. The cursor SHALL go to the last copied line. Above two lines the message SHALL be "N more lines".

#### Scenario: Copy the cursor line below itself
- **WHEN** ":t." is run on the first of the lines "a", "b"
- **THEN** the lines are "a", "a", "b" and the cursor is on row 2

#### Scenario: Copy the cursor line to the top
- **WHEN** ":co0" is run on the second of the lines "a", "b"
- **THEN** the lines are "b", "a", "b" and the cursor is on row 1

### Requirement: :m, :co, and :t refuse what Neovim refuses
A move whose target is inside its own range SHALL be refused with "E134: Cannot move a range of lines into itself"; a missing target, one past the last line, or text that is not an address SHALL be refused with "E16: Invalid range"; a bang SHALL be refused with "E477: No ! allowed"; nothing changes.

#### Scenario: A move into its own range
- **WHEN** ":1,3m2" is run on the lines "a", "b", "c"
- **THEN** the message is "E134: Cannot move a range of lines into itself" and the lines are unchanged

#### Scenario: A bad address
- **WHEN** ":m 9" or ":t x" is run on the lines "a", "b"
- **THEN** the message is "E16: Invalid range" and the lines are unchanged
