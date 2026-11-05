# global Specification

## Purpose
The global commands `:g`, `:g!`, and `:v` run an ex command on every line of a range that matches, or does not match, a pattern: the lines are marked first and keep their marks through every edit, so the command runs on exactly the lines that matched however earlier commands moved them, the whole global is one undo step, and its pattern is remembered and bounded as a search is.

## Requirements

### Requirement: :g runs a command on every matching line
`:[range]g[lobal]/{pattern}/{cmd}` SHALL first mark every line of the range, every line without one, that matches the pattern, then run the ex command `cmd` once per marked line from the top, with the cursor on that line.

#### Scenario: Substitute on matching lines
- **WHEN** ":g/a/s/x/y/" is run on the lines "ax", "bx", "ax"
- **THEN** the lines are "ay", "bx", "ay"

#### Scenario: A range limits the marked lines
- **WHEN** ":2,3g/a/s/x/y/" is run on the lines "ax", "ax", "ax"
- **THEN** the lines are "ax", "ay", "ay"

### Requirement: :g! and :v run on the lines that do not match
`:[range]g[lobal]!/{pattern}/{cmd}` and `:[range]v[global]/{pattern}/{cmd}` SHALL mark the lines of the range that do not match the pattern. `:v!` SHALL be refused with "E477: No ! allowed".

#### Scenario: :v
- **WHEN** ":v/a/d" is run on the lines "a", "b", "a"
- **THEN** the lines are "a", "a"

#### Scenario: :g!
- **WHEN** ":g!/a/d" is run on the lines "a", "b", "a"
- **THEN** the lines are "a", "a"

### Requirement: The command runs on exactly the marked lines however lines move
A marked line SHALL keep its mark while the commands run on earlier lines insert or delete lines, a marked line that such a command deletes SHALL not be visited, and a line a command inserts SHALL not be visited.

#### Scenario: Deleting every matching line
- **WHEN** ":g/a/d" is run on the lines "a1", "a2", "b", "a3"
- **THEN** the only line is "b"

#### Scenario: Deleting the line after a match
- **WHEN** ":g/a/2d" is run on the lines "a", "a", "b"
- **THEN** the run on line 1 deletes the marked line 2, which is not visited, and the lines are "a", "b"

#### Scenario: Inserting lines
- **WHEN** ":g/a/s/$/\ra/" is run on the lines "a", "b"
- **THEN** the lines are "a", "a", "b" and the inserted "a" is not visited

### Requirement: :g reads its argument as Vim does
The delimiter SHALL be any ASCII character but a letter, which is refused with "E146: Regular expressions can't be delimited by letters"; a missing closing delimiter SHALL leave the command empty; an empty pattern SHALL use the last search pattern, "E35: No previous regular expression" without one; no argument SHALL be "E148: Regular expression missing from :global". A backslash or a non-ASCII delimiter SHALL answer Not implemented.

#### Scenario: Another delimiter
- **WHEN** ":g#/#d" is run on the lines "a/b", "c"
- **THEN** the only line is "c"

#### Scenario: Empty pattern
- **WHEN** "/b" was searched and ":g//d" is run on the lines "a", "b"
- **THEN** the only line is "a"

#### Scenario: No argument
- **WHEN** ":g" is run
- **THEN** the message is "E148: Regular expression missing from :global"

### Requirement: Without a command the marked lines are listed
A global with no command SHALL list the marked lines, one per message line, and leave the cursor on the first non-blank of the last of them.

#### Scenario: Listing
- **WHEN** ":g/a" is run on the lines "a1", "b", " a2"
- **THEN** the message is "a1" and " a2" on two lines and the cursor is on row 3, column 2

### Requirement: The global reports as Vim does
When no line is marked the message SHALL be "Pattern not found: pat" for `:g` and "Pattern found in every line: pat" for `:g!` and `:v`, and nothing runs. The first command that fails SHALL stop the global and its message SHALL be shown; otherwise the last message a command gave SHALL be shown.

#### Scenario: Nothing matches
- **WHEN** ":g/z/d" is run on the line "a"
- **THEN** the message is "Pattern not found: z" and the line is "a"

#### Scenario: Every line matches
- **WHEN** ":v/a/d" is run on the lines "a", "ab"
- **THEN** the message is "Pattern found in every line: a"

#### Scenario: A failing command stops it
- **WHEN** ":g/a/foo" is run on the lines "a", "a"
- **THEN** the message is "E492: Not an editor command: foo"

### Requirement: The pattern is remembered and bounded
The pattern SHALL be compiled by the search translation under `ignorecase` and `smartcase` and SHALL become the last search pattern, the `/` register, a search history entry when typed, and the last substitute pattern. The scan that marks the lines SHALL be charged to one work budget, and when it runs out nothing SHALL run and the message SHALL be "E363: search stopped, pattern too costly here".

#### Scenario: n finds the global's pattern
- **WHEN** ":g/b" is run on the line "ab b" and then "n" is pressed
- **THEN** the cursor is on the first "b"

#### Scenario: :s reuses it
- **WHEN** ":g/b/" is run on the line "ab" and then ":s//c/"
- **THEN** the line is "ac"

### Requirement: A global is one undo step
All the changes one global makes SHALL be undone by one `u`, and `.` SHALL not repeat a global.

#### Scenario: Undo
- **WHEN** ":g/a/d" is run on the lines "a", "b", "a" and then "u" is pressed
- **THEN** the lines are "a", "b", "a"

### Requirement: A global inside a global acts on the cursor line
A global run by a global's command SHALL act on the cursor line only, and with a range other than every line SHALL be refused with "E147: Cannot do :global recursive with a range". A global SHALL stop when its command leaves the buffer it started on.

#### Scenario: Nested
- **WHEN** ":g/a/g/b/d" is run on the lines "ab", "a", "b"
- **THEN** the lines are "a", "b"

#### Scenario: Nested with a range
- **WHEN** ":g/a/1g/b/d" is run on the lines "ab", "c"
- **THEN** the message is "E147: Cannot do :global recursive with a range"
