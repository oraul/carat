# Spec Delta

## ADDED Requirements

### Requirement: Undo and redo reach plugins as buffer changes
An undo or redo SHALL be delivered to plugins as one `buffer_change` per key, with the first changed row and the rows removed and inserted there, like any other change.

#### Scenario: Undoing a deleted line
- **WHEN** "dd" is pressed on row 1 of a three-line buffer and then "u"
- **THEN** a subscribed plugin receives buffer_change with row 1, 0 rows removed, and 1 row inserted after "u"

### Requirement: A plugin edit request is undone in one step
The replacements of one plugin edit request made outside a command SHALL be undone and redone together by one "u" or "<C-r>".

#### Scenario: Two replacements, one undo
- **WHEN** a plugin replaces a character on rows 0 and 1 of ["ab", "cd"] in one request from an event, then "u" is pressed
- **THEN** the lines are ["ab", "cd"]
