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

### Requirement: :normal runs keys as typed in normal mode
`:norm[al][!] {commands}` SHALL run the characters of {commands}, read literally, as keys typed in normal mode: once at the cursor without a range, and once on each line of a range with the cursor first on column 0 of that line, stopping at the last line of the buffer. With a bang the same keys SHALL run.

#### Scenario: Append on the cursor line
- **WHEN** ":normal Ax" is run on the second of the lines "a", "b"
- **THEN** the lines are "a", "bx"

#### Scenario: Run keys on a range
- **WHEN** ":1,2normal Ax" is run on the lines "a", "b", "c"
- **THEN** the lines are "ax", "bx", "c" and the cursor is on row 2, column 1

#### Scenario: Run keys on each marked line
- **WHEN** ":g/x/normal A!" is run on the lines "x1", "a", "x2"
- **THEN** the lines are "x1!", "a", "x2!"

### Requirement: :normal ends what its keys leave unfinished
A command the keys of `:normal` leave unfinished SHALL end as if Esc were typed: insert mode is left, a pending operator is dropped, and a command line is not run. The changes the keys make SHALL be one undo step.

#### Scenario: An unfinished insert ends
- **WHEN** ":normal ihi" is run on the line "a"
- **THEN** the line is "hia", the cursor is on column 1, and the mode is normal

#### Scenario: An unfinished command line is not run
- **WHEN** ":normal :d" is run on the lines "a", "b"
- **THEN** the lines are "a", "b"

#### Scenario: The keys are one undo step
- **WHEN** ":normal xx" is run on the line "abc" and then "u" is typed
- **THEN** the line is "abc"

### Requirement: :normal refuses what Neovim refuses
`:normal` without an argument SHALL be refused with "E471: Argument required", and a `:normal` run by more than 100 nested `:normal` commands with "E192: Recursive use of :normal too deep". The keys `:normal` feeds SHALL keep the remap count of the key whose remap ran it, so a binding that runs `:normal` and then replays itself SHALL stop with "E223: Recursive mapping", while each line of a range SHALL count its own remaps.

#### Scenario: Normal without keys
- **WHEN** ":normal" is run
- **THEN** the message is "E471: Argument required"

#### Scenario: Normal too deep
- **WHEN** a key bound to ":normal" with that same key is typed
- **THEN** the message is "E192: Recursive use of :normal too deep"

#### Scenario: A binding replaying itself after normal
- **WHEN** a key bound to ":normal x" followed by that same key is typed
- **THEN** the message is "E223: Recursive mapping"

#### Scenario: A remap per line of a long range
- **WHEN** ":%normal Q" is run on 150 lines with Q bound to the keys "x"
- **THEN** the first character of every line is deleted and no message is shown

### Requirement: :p shows the lines of a range
`:[range]p[rint] [count]` SHALL show the lines of the range, the cursor line without one, or count lines from the range's last line, one per message line, and SHALL put the cursor on the last of them at the wanted column. An empty buffer SHALL be refused with "E749: Empty buffer", a bang with "E477: No ! allowed", and text after the count with "E488: Trailing characters: x".

#### Scenario: Print the cursor line
- **WHEN** ":p" is run on the second of the lines "a", "b"
- **THEN** the message is "b" and the cursor is on row 2

#### Scenario: Print a range
- **WHEN** ":1,2p" is run on the lines "a", "b", "c"
- **THEN** the message is "a" and "b" on two lines and the cursor is on row 2, column 0

#### Scenario: Print a count of lines
- **WHEN** ":p 2" is run on the first of the lines "a", "b", "c"
- **THEN** the message is "a" and "b" on two lines

#### Scenario: Print an empty buffer
- **WHEN** ":p" is run on an empty buffer
- **THEN** the message is "E749: Empty buffer"
