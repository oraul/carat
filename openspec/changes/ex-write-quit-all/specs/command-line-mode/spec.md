# Spec Delta

## ADDED Requirements

### Requirement: Exit writes a modified buffer then quits
":x", ":xit", ":exi", and ":exit" SHALL write the buffer as ":w" does when the buffer is modified or a file argument is given, and then end the editor; an unmodified buffer with no argument SHALL not be written. If the write fails the editor SHALL stay and show the write error. The bang forms SHALL behave the same, quitting after a successful write as ":wq!" does.

#### Scenario: Exit a modified buffer
- **WHEN** ":x" is run on a modified buffer for "a.txt"
- **THEN** "a.txt" holds the buffer text, the buffer is unmodified, and the editor ends

#### Scenario: Exit a clean buffer
- **WHEN** ":x" is run on an unmodified buffer
- **THEN** the file is not written, no message is shown, and the editor ends

#### Scenario: Exit with a file argument
- **WHEN** ":x b.txt" is run on an unmodified buffer for "a.txt"
- **THEN** "b.txt" holds the buffer text and the editor ends

#### Scenario: Exit with no file name
- **WHEN** ":x" is run on a modified buffer with no path
- **THEN** the editor stays and the message is "E32: No file name"

#### Scenario: Exit when the write fails
- **WHEN** ":x!" is run on a modified buffer whose file cannot be written
- **THEN** the editor stays, the message starts with "E212: Can't open file for writing", and the buffer stays modified

#### Scenario: Long and bang forms
- **WHEN** ":xit", ":exi", ":exit", ":x!", ":xit!", ":exi!", or ":exit!" is run on a modified buffer for "a.txt"
- **THEN** each writes the file and ends the editor as ":x" does

### Requirement: Write-all writes every modified buffer
":wa", ":wall", and their bang forms SHALL write every modified buffer to its own path with the message of ":w" and clear its modified flag. An unmodified buffer SHALL not be written and no message SHALL be shown. A modified buffer with no path SHALL report "E141: No file name for buffer 1" and nothing SHALL be written. With one buffer and one window the command acts on the single buffer.

#### Scenario: Write-all on a modified buffer
- **WHEN** the buffer for "a.txt" holds ["one", "two"] after an edit and ":wa" is run
- **THEN** the file "a.txt" contains "one\ntwo\n", the buffer is unmodified, and the message is "\"a.txt\" 2L, 8B written"

#### Scenario: Write-all on a clean buffer
- **WHEN** ":wa" is run on an unmodified buffer
- **THEN** nothing is written and no message is shown

#### Scenario: Write-all with no file name
- **WHEN** ":wa" is run on a modified buffer with no path
- **THEN** the message is "E141: No file name for buffer 1" and the buffer stays modified

#### Scenario: Long and bang forms
- **WHEN** ":wall", ":wa!", or ":wall!" is run on a modified buffer for "a.txt"
- **THEN** each writes the file as ":wa" does

### Requirement: Quit-all leaves the editor unless changes are unsaved
":qa", ":qall", ":quita", and ":quitall" SHALL end the editor when the buffer is unmodified and SHALL show "E37: No write since last change (add ! to override)" and stay otherwise. Their bang forms SHALL end the editor regardless of the modified flag without writing.

#### Scenario: Quit-all a clean buffer
- **WHEN** ":qa" is run on an unmodified buffer
- **THEN** the editor ends

#### Scenario: Quit-all refused
- **WHEN** ":qa" is run on a modified buffer
- **THEN** the editor stays and the message is "E37: No write since last change (add ! to override)"

#### Scenario: Forced quit-all
- **WHEN** ":qa!" is run on a modified buffer
- **THEN** the editor ends and the file is not written

#### Scenario: Long forms
- **WHEN** ":qall", ":quita", or ":quitall" is run on a modified buffer, and then with a bang
- **THEN** each is refused with E37 without the bang and ends the editor with it

### Requirement: Write-quit-all writes every modified buffer then quits
":wqa", ":wqall", ":xa", ":xall", and their bang forms SHALL write every modified buffer as ":wa" does and then end the editor. An unmodified buffer SHALL not be written and the editor SHALL end. If a write fails, or a modified buffer has no path, the editor SHALL stay and show the write error or "E141: No file name for buffer 1".

#### Scenario: Write-quit-all a modified buffer
- **WHEN** ":wqa!" is run on a modified buffer for "a.txt"
- **THEN** "a.txt" holds the buffer text and the editor ends

#### Scenario: Write-quit-all a clean buffer
- **WHEN** ":wqa" is run on an unmodified buffer
- **THEN** the file is not written and the editor ends

#### Scenario: Write-quit-all with no file name
- **WHEN** ":wqa" is run on a modified buffer with no path
- **THEN** the editor stays and the message is "E141: No file name for buffer 1"

#### Scenario: Write-quit-all when the write fails
- **WHEN** ":xa" is run on a modified buffer whose file cannot be written
- **THEN** the editor stays and the message starts with "E212: Can't open file for writing"

#### Scenario: Long and bang forms
- **WHEN** ":wqall", ":xa", ":xall", ":wqa!", ":wqall!", ":xa!", or ":xall!" is run on a modified buffer for "a.txt"
- **THEN** each writes the file and ends the editor as ":wqa" does
