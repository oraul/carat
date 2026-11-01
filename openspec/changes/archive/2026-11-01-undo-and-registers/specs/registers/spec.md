# Spec Delta

## ADDED Requirements

### Requirement: Yanks fill register 0
A yank that names no register SHALL also store its text in register "0"; a yank naming a register SHALL leave "0" alone.

#### Scenario: Register 0 survives a delete
- **WHEN** "yy" is pressed on row 0 of ["a", "b"], then "j", "dd", then the quote key, "0", "p"
- **THEN** the lines are ["a", "a"]

#### Scenario: A named yank leaves register 0
- **WHEN** "yy" is pressed on row 0 of ["a", "b"], then "j", the quote key, "b", "y", "y", then the quote key, "0", "p"
- **THEN** the lines are ["a", "b", "a"]

### Requirement: Large deletes shift through registers 1 to 9
A delete or change of whole lines, of text across lines, or with the motions "(", ")", "{", or "}" SHALL store its text in register "1", after moving "1" to "8" down to "2" to "9" and dropping the old "9", also when a register is named.

#### Scenario: Three line deletes
- **WHEN** "dd" is pressed three times on ["a", "b", "c", "x"]
- **THEN** register 1 holds "c", register 2 "b", and register 3 "a", all linewise

#### Scenario: A named line delete fills register 1 too
- **WHEN** the quote key, "a", "d", "d" are pressed on ["a", "b"]
- **THEN** registers a and 1 both hold "a"

#### Scenario: A paragraph motion uses register 1
- **WHEN** "d}" is pressed at (0, 1) of ["ab", "", "c"]
- **THEN** register 1 holds "b" and register "-" is empty

### Requirement: Small deletes fill the small delete register
A delete or change within one line that names no register SHALL store its text in register "-" and leave the numbered registers alone.

#### Scenario: x fills register -
- **WHEN** "x" is pressed at (0, 0) of ["ab", "c"], then "j", "dd", then the quote key, "-", "p"
- **THEN** the lines are ["ba"] and register 1 holds "c"

### Requirement: The black hole register takes nothing
A delete, change, or yank naming register "_" SHALL store nothing anywhere, the unnamed register included, and a put from it SHALL report "E353: Nothing in register _".

#### Scenario: Deleting into the black hole
- **WHEN** "yl" is pressed at (0, 0) of ["ab"], then the quote key, "_", "x", then "p"
- **THEN** the line is "ba"

### Requirement: Read-only registers
Register "." SHALL hold the text typed in the last insert session, ":" the last command line run, and "%" the current file's name; a put SHALL read them like any register. A delete, change, or yank naming ".", ":", "%", or "/" SHALL change nothing and show "E354: Invalid register name: '" followed by the name and "'".

#### Scenario: Put the last inserted text
- **WHEN** "i", "h", "i", Escape are pressed on [""], then the quote key, ".", "p"
- **THEN** the line is "hihi"

#### Scenario: Put the last command line
- **WHEN** ":w" is run, then the quote key, ":", "p" is pressed on [""]
- **THEN** the line is "w"

#### Scenario: Put the file name
- **WHEN** the quote key, "%", "P" is pressed in the buffer of "a.txt" holding [""]
- **THEN** the line is "a.txt"

#### Scenario: Writing a read-only register
- **WHEN** the quote key, ".", "d", "d" are pressed on ["a", "b"]
- **THEN** the lines are ["a", "b"] and the message is "E354: Invalid register name: '.'"

### Requirement: registers lists the registers
":reg", ":registers", ":di", or ":display" SHALL list, under the line "Type Name Content", one line per register holding text in the order unnamed, "0" to "9", "a" to "z", "-", ".", ":", "%": two spaces, "c", "l", or "b" for its kind, two spaces, the quote and the name, three spaces, and its text with "^J" for each line break and after linewise text. A list of names as argument SHALL keep only those registers.

#### Scenario: After a line yank
- **WHEN** "yy" is pressed on ["one"], then ":registers" is run
- **THEN** the message lines are "Type Name Content", "  l  \"\"   one^J", "  l  \"0   one^J", and "  c  \"%   a.txt"

#### Scenario: Named registers only
- **WHEN** "yy" is pressed on ["one"], then ":display 0" is run
- **THEN** the message lines are "Type Name Content" and "  l  \"0   one^J"
