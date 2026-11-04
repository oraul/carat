## MODIFIED Requirements

### Requirement: Read-only registers
Register "." SHALL hold the text typed in the last insert session, ":" the last command line run, "%" the current file's name, and "/" the last search pattern; a put SHALL read them like any register. A delete, change, or yank naming ".", ":", "%", or "/" SHALL change nothing and show "E354: Invalid register name: '" followed by the name and "'".

#### Scenario: Put the last inserted text
- **WHEN** "i", "h", "i", Escape are pressed on [""], then the quote key, ".", "p"
- **THEN** the line is "hihi"

#### Scenario: Put the last command line
- **WHEN** ":w" is run, then the quote key, ":", "p" is pressed on [""]
- **THEN** the line is "w"

#### Scenario: Put the file name
- **WHEN** the quote key, "%", "P" is pressed in the buffer of "a.txt" holding [""]
- **THEN** the line is "a.txt"

#### Scenario: Put the last search pattern
- **WHEN** "/", "b", Enter, then the quote key, "/", "P" are pressed on ["ab"] with the cursor at row 0, column 0
- **THEN** the line is "abb"

#### Scenario: Writing a read-only register
- **WHEN** the quote key, ".", "d", "d" are pressed on ["a", "b"]
- **THEN** the lines are ["a", "b"] and the message is "E354: Invalid register name: '.'"
