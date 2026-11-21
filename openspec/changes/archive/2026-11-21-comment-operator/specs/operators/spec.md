## ADDED Requirements

### Requirement: Comment operator
"gc" SHALL be a pending operator that toggles the comment of every whole line its motion or text object touches, and "gcc" SHALL toggle [count] lines from the cursor line. Counts SHALL multiply as for every operator. After a toggle the cursor SHALL be on the first non-blank of the first line, in normal mode. "gc" SHALL change no text but the comment markers.

#### Scenario: gcc comments the line
- **WHEN** "gcc" is pressed on row 0 of "a = 1" in a ruby buffer
- **THEN** the line is "# a = 1", the cursor is at (0, 0), and the mode is normal

#### Scenario: gc with a motion and a count
- **WHEN** "3gcj" is pressed on row 0 of ["a", "b", "c", "d", "e"]
- **THEN** the lines are ["# a", "# b", "# c", "# d", "e"]

#### Scenario: gcc with a count
- **WHEN** "2gcc" is pressed on row 1 of ["a", "b", "c", "d"]
- **THEN** the lines are ["a", "# b", "# c", "d"]

#### Scenario: gc with a text object
- **WHEN** "gcip" is pressed on row 0 of ["a", "b", "", "c"]
- **THEN** the lines are ["# a", "# b", "", "c"]

#### Scenario: gcc never deletes text
- **WHEN** "gcc8G" is pressed on row 2 of a buffer of ten lines
- **THEN** every line is kept, row 2 is commented, the cursor is on row 7, and the mode is normal

### Requirement: Comment toggle rule
When every non-blank line of the range is commented, a toggle SHALL uncomment each one, removing the marker and one space after it when there is one; a line left holding only blanks SHALL become empty. Otherwise a toggle SHALL comment every non-blank line, inserting the marker and one space at the smallest indent of the range's non-blank lines. A line is commented when its first non-blank characters are the marker. Blank lines SHALL be left untouched either way.

#### Scenario: Uncomment removes the marker and one space
- **WHEN** "gc2j" is pressed on row 0 of ["# a", "#b", "  #  c"]
- **THEN** the lines are ["a", "b", "   c"]

#### Scenario: A line of only the marker becomes empty
- **WHEN** "gcj" is pressed on row 0 of ["# a", "  #"]
- **THEN** the lines are ["a", ""]

#### Scenario: A mixed range is commented
- **WHEN** "gcj" is pressed on row 0 of ["# a", "b"]
- **THEN** the lines are ["# # a", "# b"]

#### Scenario: Blank lines are untouched
- **WHEN** "gc2j" is pressed on row 0 of ["a", "", "b"]
- **THEN** the lines are ["# a", "", "# b"], and uncommenting them again gives ["a", "", "b"]

#### Scenario: The marker goes at the smallest indent
- **WHEN** "gcj" is pressed on row 0 of ["    a", "  b"]
- **THEN** the lines are ["  #   a", "  # b"]

### Requirement: Comment marker by filetype
The comment marker SHALL come from the buffer's filetype through one table: "#" for ruby. A buffer whose filetype has no row in the table, or no filetype, SHALL use "#".

#### Scenario: An unknown filetype uses the default marker
- **WHEN** "gcc" is pressed on row 0 of "a" in a buffer named "a.txt"
- **THEN** the line is "# a"

### Requirement: Repeating and undoing a comment toggle
A whole toggle SHALL be one undo step, and "." SHALL repeat it on the lines at the cursor with the same count.

#### Scenario: One undo restores the toggled lines
- **WHEN** "3gcc" is pressed on row 0 of ["a", "b", "c"], then "u"
- **THEN** the lines are ["a", "b", "c"]

#### Scenario: Dot repeats the toggle
- **WHEN** "gcc" is pressed on row 0 of ["a", "b", "c"], then "j."
- **THEN** the lines are ["# a", "# b", "c"]

### Requirement: Comment operator in the visual modes
"gc" in visual, visual_line, and visual_block SHALL toggle the comment of every line the selection touches by the same rule, leave visual mode, and put the cursor on the first non-blank of the selection's first line.

#### Scenario: Visual gc
- **WHEN** "vjgc" is pressed on row 0 of ["a", "b", "c"]
- **THEN** the lines are ["# a", "# b", "c"] and the mode is normal

#### Scenario: Visual line gc uncomments
- **WHEN** "Vjgc" is pressed on row 0 of ["# a", "# b"]
- **THEN** the lines are ["a", "b"]

#### Scenario: Visual block gc toggles whole lines
- **WHEN** Ctrl-v, "j", "l", "gc" are pressed at (0, 1) of ["abc", "def"]
- **THEN** the lines are ["# abc", "# def"]
