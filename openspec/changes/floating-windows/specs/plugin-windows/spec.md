## ADDED Requirements

### Requirement: A plugin opens, moves, and closes floats
A plugin SHALL open a float holding the lines it gives, placed and sized as a float spec says, and the request SHALL answer the float's window id; the float's buffer SHALL be a scratch buffer the plugin owns, never listed and never written. A plugin SHALL move and close its own floats by id. The plugin API version SHALL be 2.3.

#### Scenario: Open and close a float
- **WHEN** a test plugin opens a float with the lines "one" and "two" at row 1, column 2 of the editor, 2 rows by 8 columns, with enter
- **THEN** the answer is a new window id, the float shows "one" and "two", it is the current window, and closing that id removes it and makes the window under it current

#### Scenario: Move a float
- **WHEN** the plugin moves its float to row 4, column 6
- **THEN** the next frame shows the float there and the rows it left show the window under it

### Requirement: A plugin's float requests are checked
An unknown anchor, a size below one row or column, a z order outside 0 to 1000, a full tab page, an unknown id, and another plugin's float SHALL fail with a message and change nothing.

#### Scenario: Refused requests
- **WHEN** a plugin opens a float with the anchor "window", or closes a float another plugin opened
- **THEN** the request fails with a message and every float stays as it was

#### Scenario: API version
- **WHEN** a plugin declares API 2.3
- **THEN** it is accepted, and a plugin declaring 2.4 is refused
