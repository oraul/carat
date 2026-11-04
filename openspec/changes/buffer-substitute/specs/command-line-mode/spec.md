## ADDED Requirements

### Requirement: Ex commands take a range of lines
A command line SHALL accept a range before the command name: `%` for every line, `.` for the cursor line, `$` for the last line, a line number, and `'<` and `'>` for the first and last line of the window's last visual selection, as one address or two joined by `,`, an empty address standing for the cursor line.

#### Scenario: Whole buffer
- **WHEN** ":%s/a/b/" is run on a buffer of three lines each holding "a"
- **THEN** every line holds "b"

#### Scenario: Two numbers
- **WHEN** ":2,3s/a/b/" is run on a buffer of four lines each holding "a"
- **THEN** lines 2 and 3 hold "b" and lines 1 and 4 hold "a"

#### Scenario: Visual marks
- **WHEN** lines 2 and 3 were selected with "V" and left, and ":'<,'>s/a/b/" is run
- **THEN** only lines 2 and 3 change

### Requirement: A wrong range is refused
A range reaching past the last line SHALL report "E16: Invalid range", a first address after the second "E493: Backwards range given", `'<` or `'>` with no selection "E20: Mark not set", a range before a command that takes none "E481: No range allowed", and an address with `+`, `-`, `;`, a pattern, or another mark "Not implemented: range " followed by the range; none SHALL change anything.

#### Scenario: Past the end
- **WHEN** ":5s/a/b/" is run on a buffer of three lines
- **THEN** the message is "E16: Invalid range" and nothing changes

#### Scenario: Backwards
- **WHEN** ":3,1s/a/b/" is run
- **THEN** the message is "E493: Backwards range given" and nothing changes

#### Scenario: No selection yet
- **WHEN** ":'<,'>s/a/b/" is run in a window that never had a visual selection
- **THEN** the message is "E20: Mark not set"

#### Scenario: A command that takes no range
- **WHEN** ":1,2w" is run
- **THEN** the message is "E481: No range allowed" and nothing is written

### Requirement: A range alone moves the cursor
A command line holding only a range SHALL move the cursor to the range's last line, keeping the wanted column as `G` does, and report nothing.

#### Scenario: Go to a line
- **WHEN** ":3" is run on a buffer of five lines
- **THEN** the cursor is on line 3

#### Scenario: Go to the last line
- **WHEN** ":$" is run
- **THEN** the cursor is on the last line

### Requirement: Colon in a visual mode opens a range of the selection
Pressing ":" in visual, visual line, or visual block mode SHALL leave the mode, keeping the selection as the last one, and enter command-line mode with "'<,'>" on the command line.

#### Scenario: Colon after a linewise selection
- **WHEN** "Vj:" is typed
- **THEN** the mode is cmdline and the command line holds "'<,'>"
