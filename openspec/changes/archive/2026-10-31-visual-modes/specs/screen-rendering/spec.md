# Spec Delta

## MODIFIED Requirements

### Requirement: Message row content
The message row SHALL show, in priority order, the command line prefixed by ":" in command-line mode, or by a plugin's prompt text in place of ":" while a plugin prompt is open, the pending message if one was set by the last action, or "-- INSERT --" in insert mode, "-- VISUAL --", "-- VISUAL LINE --", or "-- VISUAL BLOCK --" in the visual modes, and SHALL be blank otherwise. A message SHALL stay until the next key is handled. The cursor SHALL be placed after the command line text.

#### Scenario: Message replaces the mode indicator
- **WHEN** ":q" is run on a modified buffer
- **THEN** the message row reads "E37: No write since last change (add ! to override)"

#### Scenario: Message clears on the next key
- **WHEN** a message is showing and "l" is pressed
- **THEN** the message row is blank

#### Scenario: Prompt in place of the colon
- **WHEN** a plugin prompts "Rename to: " with the initial value "a.rb"
- **THEN** the message row reads "Rename to: a.rb" and the cursor is in column 15 of it

#### Scenario: Visual block indicator
- **WHEN** "<C-v>" is pressed in normal mode
- **THEN** the message row reads "-- VISUAL BLOCK --"

## ADDED Requirements

### Requirement: The selection is drawn with the Visual highlight
In a visual mode the current window SHALL draw every selected character with the Visual highlight group, and the cell after a line's last character when its line break is selected; the cell under the cursor SHALL keep its own highlight so the cursor shows on top. Other windows, including those showing the same buffer, SHALL draw no selection.

#### Scenario: Charwise selection
- **WHEN** "vl" is pressed at (0, 0) of "abc"
- **THEN** the cell of "a" uses the Visual highlight, the cell of "b" under the cursor does not, and the cell of "c" does not

#### Scenario: Linewise selection includes the line end
- **WHEN** "V" is pressed at (0, 0) of "ab"
- **THEN** the cells of "b" and of the line end after it use the Visual highlight

#### Scenario: Two windows on one buffer
- **WHEN** ":split" then "Vj" are pressed
- **THEN** only the current window draws the Visual highlight

### Requirement: A block is drawn on display columns
A blockwise selection SHALL be drawn over the same display columns on every row of the block, from the leftmost to the rightmost cell of the anchor's and the cursor's characters, so a tab or a wide character on its edge is covered cell by cell; after "$" it SHALL reach every row's end.

#### Scenario: Block over a tab
- **WHEN** "<C-v>ljj" is pressed at (0, 1) of ["abcd", "a\tb", "abcd"] with tabstop 4
- **THEN** display columns 1 and 2 of the tab's row use the Visual highlight and its column 3 does not

#### Scenario: Block over a wide character
- **WHEN** "<C-v>j" is pressed at (0, 1) of ["a中b", "abcd"]
- **THEN** the block covers display columns 1 and 2 on both rows
