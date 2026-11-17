## ADDED Requirements

### Requirement: :j joins the lines of a range
`:[range]j[oin][!] [count]` SHALL join the lines of the range into one, the cursor line and the next without a range, as one undo step. A count SHALL join count lines from the range's last line, stopping at the last line of the buffer. The cursor SHALL go to the first non-blank of the joined line.

#### Scenario: Join the cursor line with the next
- **WHEN** ":j" is run on the first of the lines "a", "  b", "c"
- **THEN** the lines are "a b", "c" and the cursor is on row 1, column 0

#### Scenario: Join a range
- **WHEN** ":1,3j" is run on the lines "a", "b", "c", "d"
- **THEN** the lines are "a b c", "d"

### Requirement: :j spaces the joined lines as Neovim does
Without a bang each joined line SHALL lose its leading blanks and follow one space, none when the line before ends with a blank or is empty, or the joined line starts with ")" or is empty; with a bang the lines SHALL be put together as they are.

#### Scenario: Join with a bang
- **WHEN** ":j!" is run on the first of the lines "a", "  b"
- **THEN** the only line is "a  b"

#### Scenario: Join a count
- **WHEN** ":2j 3" is run on the lines "a", "b", "c", "d", "e"
- **THEN** the lines are "a", "b c d", "e"

### Requirement: :j of one line joins it with the next
A range of one line SHALL join that line and the next, except that one given with two addresses, or the last line of the buffer, SHALL change nothing.

#### Scenario: Join on the last line
- **WHEN** ":j" is run on the last of the lines "a", "b"
- **THEN** the lines are "a", "b"

#### Scenario: Join is one undo step
- **WHEN** ":1,3j" is run on the lines "a", "b", "c" and then "u" is typed
- **THEN** the lines are "a", "b", "c"

### Requirement: :> and :< shift the lines of a range
`:[range]> [count]` and `:[range]< [count]` SHALL shift the lines of the range, the cursor line without one, right or left by `shiftwidth` columns once for each `>` or `<` typed, as one undo step. A count SHALL shift count lines from the range's last line, stopping at the last line of the buffer. The cursor SHALL go to the first non-blank of the last shifted line.

#### Scenario: Shift the cursor line right
- **WHEN** ":>" is run on the first of the lines "a", "b" with a shiftwidth of 2
- **THEN** the lines are "  a", "b" and the cursor is on row 1, column 2

### Requirement: :> and :< report above two lines
An empty line SHALL stay empty and a left shift SHALL stop at column 0. Above two lines the message SHALL be "N lines >ed M time" or "N lines <ed M times", as Neovim's 'report' shows.

#### Scenario: Shift a range twice
- **WHEN** ":1,3>>" is run on the lines "a", "b", "c" with a shiftwidth of 2
- **THEN** the lines are "    a", "    b", "    c", the cursor is on row 3, and the message is "3 lines >ed 2 times"

#### Scenario: Shift left with a count
- **WHEN** ":< 2" is run on the first of the lines "    a", "  b", "c"
- **THEN** the lines are "  a", "b", "c" and the cursor is on row 2, column 0

#### Scenario: Shift is one undo step
- **WHEN** ":1,2>" is run on the lines "a", "b" and then "u" is typed
- **THEN** the lines are "a", "b"

### Requirement: :j, :>, and :< refuse what Neovim refuses
A zero count SHALL be refused with "E939: Positive count required", anything after the count with "E488: Trailing characters: x", and a bang on `:>` or `:<` with "E477: No ! allowed"; nothing changes.

#### Scenario: A zero count for join
- **WHEN** ":j 0" is run
- **THEN** the message is "E939: Positive count required"

#### Scenario: Text after the shift
- **WHEN** ":> x" is run on the lines "a", "b"
- **THEN** the message is "E488: Trailing characters: x" and the lines are unchanged

#### Scenario: A bang on a shift
- **WHEN** ":>!" is run on the lines "a", "b"
- **THEN** the message is "E477: No ! allowed" and the lines are unchanged
