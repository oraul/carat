## ADDED Requirements

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
`:normal` without an argument SHALL be refused with "E471: Argument required", and a `:normal` run by more than 100 nested `:normal` commands with "E192: Recursive use of :normal too deep".

#### Scenario: Normal without keys
- **WHEN** ":normal" is run
- **THEN** the message is "E471: Argument required"

#### Scenario: Normal too deep
- **WHEN** a key bound to ":normal" with that same key is typed
- **THEN** the message is "E192: Recursive use of :normal too deep"

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
