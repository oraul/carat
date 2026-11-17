# line-commands Specification

## Purpose
Line commands are the ex commands that work on whole lines of a range, starting with `:d[elete]`, which deletes the lines of a range or a count of lines into a register as a linewise delete does, and refuses what Vim refuses.

## Requirements

### Requirement: :d deletes a range of lines into a register
`:[range]d[elete] [x] [count]` SHALL delete the lines of the range, the cursor line without one, into register `x`, or the unnamed register without one, shifting the numbered registers as a linewise delete does. A count SHALL delete count lines from the range's last line, stopping at the last line of the buffer. The cursor SHALL go to the first non-blank of the line that takes the first deleted line's place, the last line when none does.

#### Scenario: The cursor line
- **WHEN** ":d" is run on the second of the lines "a", " b", "c"
- **THEN** the lines are "a", "c" and the cursor is on row 2, column 0

#### Scenario: A range into a register
- **WHEN** ":1,2d x" is run on the lines "a", "b", "c" and then "\"xp" is typed
- **THEN** the lines are "c", "a", "b"

#### Scenario: A count
- **WHEN** ":2d 2" is run on the lines "a", "b", "c", "d"
- **THEN** the lines are "a", "d"

#### Scenario: The last lines
- **WHEN** ":2,3d" is run on the lines "a", "b", "c"
- **THEN** the only line is "a" and the cursor is on row 1

### Requirement: :d refuses what Vim refuses
A bang SHALL be refused with "E477: No ! allowed", a register that cannot be written or anything after the count with "E488: Trailing characters: x", and a zero count with "E939: Positive count required"; nothing is deleted.

#### Scenario: A read-only register
- **WHEN** ":d /" is run
- **THEN** the message is "E488: Trailing characters: /"

#### Scenario: A zero count
- **WHEN** ":d 0" is run
- **THEN** the message is "E939: Positive count required"

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
