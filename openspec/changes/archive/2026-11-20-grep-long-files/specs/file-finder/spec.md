## MODIFIED Requirements

### Requirement: The picker reads the finder's files once and within bounds
The picker's files SHALL be the finder's listing, each read once when the picker opens. A file that cannot be read, holds a NUL byte, or is over the host's read limit SHALL add no line; every line of a file within the read limit SHALL be stored, a line SHALL be cut at the last character boundary at or under 400 bytes, and at most 400,000 lines SHALL be stored. Each key SHALL search the stored lines within the per-key bound of the requirement Each key searches a bounded number of lines.

#### Scenario: The picker stores only bounded lines of each file
- **WHEN** a file holds 1200 lines, a line holds 500 bytes, a line holds a multi-byte character the cut would split, or more than 400,000 lines are stored
- **THEN** all 1200 lines of the file are stored, the line is cut at a character boundary at or under 400 bytes, and the title marks the store cap with `+`

#### Scenario: A match past the 1000th line is found
- **WHEN** a file of 2000 lines holds the typed text only on line 1500 and the user presses Enter on its row
- **THEN** the row shows the file's path and line 1500, and the file opens with the cursor on line 1500

#### Scenario: A tree the size of this repository is searched whole
- **WHEN** the project holds 150,001 lines in files of at most 1000 lines each
- **THEN** every line is stored and the title's stored count has no `+`, a key checks 30,000 of them, and keys that extend the text continue through the rest

#### Scenario: Files that cannot be searched are left out
- **WHEN** the project holds a binary file, a file over the read limit, an empty file, and an ignored directory
- **THEN** none of them adds a line to the count or a row

### Requirement: The grep preview is centred and clamped at the file's ends
The preview window SHALL start at the row's line number less half the float's height, moved to start at line 1 when that is lower, and to end at the file's last line when it would end later; a file with fewer lines SHALL show whole. A line the picker did not store because it is empty SHALL show as an empty line, the empty lines at the file's end included, and the window SHALL cover no line past the last the picker read of a file.

#### Scenario: The preview is centred on the matched line
- **WHEN** the highlighted row is line 50 of a file of 100 lines on a 24-row screen
- **THEN** the preview shows lines 41 to 58 with line 50 the tenth

#### Scenario: The preview is clamped at the file's start and end
- **WHEN** the highlighted row is line 3, or line 38 of 40, or line 1195 of a file of 1200 lines
- **THEN** the preview shows lines 1 to 18, 23 to 40, or 1183 to 1200

#### Scenario: The preview ends at the file's last line
- **WHEN** the highlighted row's file ends in empty lines after its last non-empty line
- **THEN** the preview shows those empty lines below it
