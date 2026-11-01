# Spec Delta

## MODIFIED Requirements

### Requirement: Modified flag follows edits and saves
A buffer SHALL be modified exactly when an edit changed its text since it was loaded, reloaded, or saved. Every primitive except reload SHALL count one change; changing the text back by another edit SHALL leave the buffer modified. Undo or redo that returns the text to the state it was in when it was last loaded, reloaded, or saved SHALL leave the buffer unmodified, and undo or redo away from that state SHALL make it modified again.

#### Scenario: Load, edit, save
- **WHEN** a buffer is loaded, then text is inserted, then it is marked saved
- **THEN** it is unmodified after loading, modified after the insert, and unmodified after the save

#### Scenario: Editing back does not clear the flag
- **WHEN** "x" is inserted into a saved buffer and then deleted again
- **THEN** the text equals the saved text and the buffer is still modified

#### Scenario: Write then edit
- **WHEN** "x" is pressed in a buffer, ":w" is run, and "x" is pressed again
- **THEN** the buffer is unmodified after the write and modified after the second "x"

#### Scenario: Undo back to the write
- **WHEN** "x" is pressed in a buffer, ":w" is run, "x" is pressed again, and then "u"
- **THEN** the buffer is unmodified after "u" and modified again after "<C-r>"

#### Scenario: Undo to the loaded text
- **WHEN** "x" is pressed in a freshly opened buffer and then "u"
- **THEN** the buffer is unmodified
