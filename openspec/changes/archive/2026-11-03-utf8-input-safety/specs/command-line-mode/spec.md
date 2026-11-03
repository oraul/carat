## ADDED Requirements

### Requirement: Edit names the first line with an illegal byte
":e path" of a file that is not valid UTF-8 SHALL open it like any other file and SHALL add "[ILLEGAL BYTE in line N]", N being the first line holding a byte outside a well-formed UTF-8 sequence, between the quoted file name and the line and byte counts. A failure to read or load the file SHALL be answered with an E484 message and SHALL leave the editor running.

#### Scenario: Open a Latin-1 file
- **WHEN** ":e l.txt" is run and "l.txt" holds "ok\ncaf\xE9\n"
- **THEN** the lines are ["ok", "caf\xE9"] and the message is "\"l.txt\" [ILLEGAL BYTE in line 2] 2L, 8B"

#### Scenario: Write an unedited file with an illegal byte
- **WHEN** "l.txt" holding "ok\ncaf\xE9\n" is opened and ":w" is run
- **THEN** the file holds "ok\ncaf\xE9\n" again
