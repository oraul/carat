## ADDED Requirements

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
