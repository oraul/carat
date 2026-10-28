# motions Specification

## Purpose
Motions move the cursor and define the text an operator works on. Each motion maps the editor state and a count to a target position with a kind, linewise or charwise, and an inclusive flag, so that one definition serves cursor movement and operator ranges alike.

## Requirements

### Requirement: Foundation motions take a count
"h", "l", "j", "k", and "$" SHALL accept a count: "h" and "l" move count columns, stopping at the line edges; "j" and "k" move count rows, stopping at the buffer edges; "$" moves to the end of the line count minus one rows down. "G" with a count SHALL go to that line, clamped to the last line, and "gg" with a count SHALL go to that line too; without a count they go to the last and first lines. A motion that cannot move at all SHALL do nothing.

#### Scenario: Counted h stops at column 0
- **WHEN** the cursor is at (0, 2) of "abcdef" and "5h" is pressed
- **THEN** the cursor is at (0, 0)

#### Scenario: Counted j stops at the last line
- **WHEN** the cursor is on row 0 of three lines and "9j" is pressed
- **THEN** the cursor is on row 2

#### Scenario: Counted G goes to a line
- **WHEN** "2G" is pressed in five lines
- **THEN** the cursor is on row 1

#### Scenario: Counted gg goes to a line
- **WHEN** "3gg" is pressed in five lines
- **THEN** the cursor is on row 2

#### Scenario: Counted dollar
- **WHEN** the cursor is at (0, 0) of ["abc", "de"] and "2$" is pressed
- **THEN** the cursor is at (1, 1)

### Requirement: Find and till motions
"f" SHALL move to the count-th occurrence of the following character to the right on the line, "F" to the left, "t" to just before it to the right, and "T" to just after it to the left. When there is no such occurrence the cursor SHALL not move. ";" SHALL repeat the last of these in the same direction and "," in the opposite direction; after "t" or "T" a repeat SHALL skip an adjacent match.

#### Scenario: f and F
- **WHEN** the cursor is at (0, 0) of "a.b.c" and "f." is pressed, then "F."
- **THEN** the cursor is at (0, 1) after "f." and still at (0, 1) after "F." because there is no "." to its left

#### Scenario: Counted f
- **WHEN** the cursor is at (0, 0) of "a.b.c" and "2f." is pressed
- **THEN** the cursor is at (0, 3)

#### Scenario: t stops before the character
- **WHEN** the cursor is at (0, 0) of "abc" and "tc" is pressed
- **THEN** the cursor is at (0, 1)

#### Scenario: T stops after the character
- **WHEN** the cursor is at (0, 2) of "abc" and "Ta" is pressed
- **THEN** the cursor is at (0, 1)

#### Scenario: Missing character does nothing
- **WHEN** the cursor is at (0, 0) of "abc" and "fz" is pressed
- **THEN** the cursor is at (0, 0)

#### Scenario: Semicolon and comma repeat
- **WHEN** the cursor is at (0, 0) of "a.b.c.d" and "f." then ";" then ";" then "," are pressed
- **THEN** the cursor is at (0, 1), then (0, 3), then (0, 5), then (0, 3)

#### Scenario: Semicolon after t skips the adjacent match
- **WHEN** the cursor is at (0, 0) of "a.b.c" and "t." then ";" are pressed
- **THEN** the cursor is at (0, 0) after "t." and at (0, 2) after ";"

### Requirement: Line motions go to the first non-blank
"+" SHALL move count lines down and "-" count lines up, each to the first non-blank character; "_" SHALL move count minus one lines down to the first non-blank character. They are linewise.

#### Scenario: Plus and minus
- **WHEN** the cursor is at (0, 3) of ["abcd", "  ef", "gh"] and "+" is pressed, then "-"
- **THEN** the cursor is at (1, 2) after "+" and at (0, 0) after "-"

#### Scenario: Underscore with a count
- **WHEN** the cursor is at (0, 0) of ["ab", "  cd", "ef"] and "2_" is pressed
- **THEN** the cursor is at (1, 2)

### Requirement: Word motions
"w" SHALL move to the start of the next word, "b" to the start of the current or previous word, "e" to the end of the current or next word, and "ge" to the end of the previous word, count times; "W", "B", "E", and "gE" SHALL do the same over WORDs, which are sequences of non-blank characters. A word is a sequence of keyword characters or a sequence of other non-blank characters; an empty line counts as a word. "w" and "b" are exclusive, "e" and "ge" inclusive.

#### Scenario: w over punctuation
- **WHEN** the cursor is at (0, 0) of "foo.bar baz" and "w" is pressed three times
- **THEN** the cursor is at (0, 3), then (0, 4), then (0, 8)

#### Scenario: W over a WORD
- **WHEN** the cursor is at (0, 0) of "foo.bar baz" and "W" is pressed
- **THEN** the cursor is at (0, 8)

#### Scenario: w crosses lines and stops on an empty line
- **WHEN** the cursor is at (0, 4) of ["one two", "", "three"] and "w" is pressed twice
- **THEN** the cursor is at (1, 0), then (2, 0)

#### Scenario: w at the end of the buffer
- **WHEN** the cursor is at (0, 4) of "one two" and "w" is pressed
- **THEN** the cursor is at (0, 6)

#### Scenario: b and B
- **WHEN** the cursor is at (0, 10) of "foo.bar baz" and "b" is pressed, then "B"
- **THEN** the cursor is at (0, 8), then (0, 0)

#### Scenario: e and E
- **WHEN** the cursor is at (0, 0) of "foo.bar baz" and "e" is pressed, then "E"
- **THEN** the cursor is at (0, 2), then (0, 6)

#### Scenario: ge
- **WHEN** the cursor is at (0, 8) of "foo.bar baz" and "ge" is pressed twice
- **THEN** the cursor is at (0, 6), then (0, 3)

#### Scenario: gE
- **WHEN** the cursor is at (0, 10) of "foo.bar baz" and "gE" is pressed
- **THEN** the cursor is at (0, 6)

#### Scenario: Counted word motion
- **WHEN** the cursor is at (0, 0) of "a b c d" and "3w" is pressed
- **THEN** the cursor is at (0, 6)

### Requirement: Sentence and paragraph motions
")" SHALL move to the start of the next sentence and "(" to the start of the current or previous sentence; "}" SHALL move to the next empty line and "{" to the previous one, or to the end or start of the buffer when there is none. A sentence ends at ".", "!" or "?" followed by optional closing characters and a blank or the end of the line; an empty line is a boundary for both. All four are exclusive.

#### Scenario: Sentence forward and back
- **WHEN** the cursor is at (0, 0) of "One. Two! Three" and ")" is pressed twice, then "("
- **THEN** the cursor is at (0, 5), then (0, 10), then (0, 5)

#### Scenario: Sentence across lines
- **WHEN** the cursor is at (0, 0) of ["One two.", "Three."] and ")" is pressed
- **THEN** the cursor is at (1, 0)

#### Scenario: Paragraph forward and back
- **WHEN** the cursor is at (0, 0) of ["a", "b", "", "c", "d"] and "}" is pressed, then "}" again, then "{"
- **THEN** the cursor is at (2, 0), then (4, 0), then (2, 0)

#### Scenario: Paragraph back to the start
- **WHEN** the cursor is at (1, 0) of ["a", "b"] and "{" is pressed
- **THEN** the cursor is at (0, 0)

### Requirement: Screen motions
"H" SHALL move to the top line of the window, "M" to the middle of the visible lines, and "L" to the bottom line of the window, keeping the wanted column; a count on "H" or "L" SHALL move that many lines from the edge. When moving the cursor they SHALL stay scrolloff lines from a window edge that is not a buffer edge. They are linewise.

#### Scenario: H M L in a scrolled window
- **WHEN** a window of 8 text rows shows rows 10 to 17 of forty lines with scrolloff 0 and "H", "M", "L" are pressed in turn
- **THEN** the cursor is on row 10, then 13, then 17

#### Scenario: L honors scrolloff
- **WHEN** a window of 8 text rows shows rows 0 to 7 of forty lines with scrolloff 2 and "L" is pressed
- **THEN** the cursor is on row 5

#### Scenario: Counted H
- **WHEN** a window of 8 text rows shows rows 10 to 17 of forty lines with scrolloff 0 and "3H" is pressed
- **THEN** the cursor is on row 12

### Requirement: Motions give operators a range
Under an operator a charwise exclusive motion SHALL cover the text from the cursor up to but not including the target, an inclusive motion SHALL include the target character, and a linewise motion SHALL cover whole lines from the cursor line to the target line. A backward motion SHALL cover the text from the target to the cursor.

#### Scenario: Exclusive forward motion
- **WHEN** "dw" is pressed at (0, 0) of "one two"
- **THEN** the line is "two"

#### Scenario: Inclusive motion
- **WHEN** "de" is pressed at (0, 0) of "one two"
- **THEN** the line is " two"

#### Scenario: Backward motion
- **WHEN** "db" is pressed at (0, 4) of "one two"
- **THEN** the line is "two"

#### Scenario: Linewise motion
- **WHEN** "dj" is pressed on row 0 of ["a", "b", "c"]
- **THEN** the lines are ["c"]

#### Scenario: Find motion under an operator
- **WHEN** "df." is pressed at (0, 0) of "ab.cd"
- **THEN** the line is "cd"

#### Scenario: Till motion under an operator
- **WHEN** "dt." is pressed at (0, 0) of "ab.cd"
- **THEN** the line is ".cd"

### Requirement: Exclusive motions ending in column 0 are adjusted
When an exclusive motion under an operator ends in column 0 of a later line, the range SHALL end at the end of the previous line inclusively, and SHALL become linewise when the motion started at or before the first non-blank character of its line. "w" under an operator SHALL stop at the end of the line when the last word moved over ends there.

#### Scenario: d} deletes whole lines
- **WHEN** "d}" is pressed at (0, 0) of ["a", "b", "", "c"]
- **THEN** the lines are ["", "c"]

#### Scenario: d} from inside a line keeps the start
- **WHEN** "d}" is pressed at (0, 1) of ["ab", "cd", "", "e"]
- **THEN** the lines are ["a", "", "e"]

#### Scenario: dw at the end of a line stays on the line
- **WHEN** "dw" is pressed at (0, 4) of ["one two", "three"]
- **THEN** the lines are ["one ", "three"]
