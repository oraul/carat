## MODIFIED Requirements

### Requirement: Replace primitive
The buffer SHALL replace a charwise range with text in one step, equivalent to deleting the range and inserting the text at its start, and SHALL count it as one change.

#### Scenario: Replace within a line
- **WHEN** the range from (0, 1) to (0, 3) of the lines ["abcd"] is replaced with "XYZ"
- **THEN** the lines are ["aXYZd"]

#### Scenario: Replace counts once
- **WHEN** the range from (0, 1) to (1, 1) of the lines ["ab", "cd"] is replaced with "-\n-"
- **THEN** the lines are ["a-", "-d"] and the buffer's change count went up by one

### Requirement: Modified flag follows edits and saves
A buffer SHALL be modified exactly when an edit changed its text since it was loaded, reloaded, or saved. Every primitive except reload SHALL count one change; changing the text back by another edit SHALL leave the buffer modified.

#### Scenario: Load, edit, save
- **WHEN** a buffer is loaded, then text is inserted, then it is marked saved
- **THEN** it is unmodified after loading, modified after the insert, and unmodified after the save

#### Scenario: Editing back does not clear the flag
- **WHEN** "x" is inserted into a saved buffer and then deleted again
- **THEN** the text equals the saved text and the buffer is still modified

#### Scenario: Write then edit
- **WHEN** "x" is pressed in a buffer, ":w" is run, and "x" is pressed again
- **THEN** the buffer is unmodified after the write and modified after the second "x"

## ADDED Requirements

### Requirement: Reload primitive
The buffer SHALL replace all of its lines with a given list of lines in one step, keeping at least one line, counting it as one change, and leaving the buffer unmodified.

#### Scenario: Reload replaces the text
- **WHEN** a modified buffer with the lines ["a", "b"] is reloaded with ["x"]
- **THEN** the lines are ["x"], the buffer is unmodified, and its change count went up by one

#### Scenario: Reload to nothing
- **WHEN** a buffer is reloaded with []
- **THEN** the lines are [""]

### Requirement: Every edit is recorded
Every primitive call SHALL produce one change record holding the buffer's id, the first row it changed, the lines it removed, and the lines it inserted, so the text before the edit can be rebuilt from the text after it.

#### Scenario: Deleting a line
- **WHEN** "dd" is pressed on row 1 of the lines ["a", "b", "c"]
- **THEN** the record has row 1, removed ["b"], and inserted []

#### Scenario: Typing a character
- **WHEN** "x" is typed in insert mode at row 0, column 1 of the lines ["ab"]
- **THEN** the record has row 0, removed ["ab"], and inserted ["axb"]

### Requirement: Edits are grouped into transactions
The records of one command SHALL be grouped into one transaction with the cursor before and after it: a normal-mode, visual-mode, or command-line command; an insert session from the command that entered insert mode to leaving it; and one plugin edit request. An edit outside these SHALL be a transaction of its own; a command that edits nothing SHALL produce none.

#### Scenario: A multi-edit command
- **WHEN** "3dd" is pressed on the lines ["a", "b", "c", "d"]
- **THEN** exactly one transaction closes, holding the records of the deletion, with the cursor before at row 0

#### Scenario: Opening a line and typing
- **WHEN** "o", "x", "y", and Escape are pressed
- **THEN** exactly one transaction closes when Escape is pressed, holding the opened line and the two typed characters

#### Scenario: A reload
- **WHEN** ":e!" is run on a modified buffer
- **THEN** exactly one transaction closes, holding one record that removes the edited lines and inserts the file's lines

#### Scenario: A plugin edit
- **WHEN** a plugin applies two replacements to a buffer in one request outside a command
- **THEN** exactly one transaction closes, holding two records

#### Scenario: A motion
- **WHEN** "j" is pressed
- **THEN** no transaction closes

### Requirement: Listed buffers have a stable id
Every buffer SHALL receive an integer id when it first enters the buffer list, distinct from the id of every other buffer of the editor, and SHALL keep it for as long as the editor runs.

#### Scenario: Two files
- **WHEN** "a.txt" is open and ":e b.txt" is run
- **THEN** the two buffers have different ids and "a.txt" keeps the id it had
