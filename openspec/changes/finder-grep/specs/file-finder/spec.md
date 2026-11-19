## ADDED Requirements

### Requirement: Space f g opens the grep picker
In normal mode `<leader>fg` SHALL open the finder's content picker: the prompt `> ` and a bordered float titled `Grep K/N` (K rows kept, N lines stored), reading `Type to search the files' lines` until text is typed. The key SHALL be a default binding of the plugin, which the configuration may replace, and the action SHALL be listed in the palette.

#### Scenario: Space f g opens the picker
- **WHEN** the user presses `<Space>fg`
- **THEN** the mode is command-line and a float titled `Grep 0/N` reads `Type to search the files' lines`

### Requirement: The picker reads the finder's files once and within bounds
The picker's files SHALL be the finder's listing, each read once when the picker opens. A file that cannot be read, holds a NUL byte, or is over the host's read limit SHALL add no line; only its first 1000 lines SHALL be stored, a line SHALL be cut at 400 bytes, and at most 100,000 lines SHALL be stored.

#### Scenario: Files that cannot be searched are left out
- **WHEN** the project holds a binary file, a file over the read limit, an empty file, and an ignored directory
- **THEN** none of them adds a line to the count or a row

### Requirement: Typing lists the matching lines best first
Every change of the typed text SHALL list again the lines in which every typed byte appears in order, ignoring ASCII case, each row as the file's path, the line number, and the line's text. Rows SHALL rank by the finder's path rules applied to the line: a better score first, then a shorter path, then listing order. With no match the float SHALL read `No match`.

#### Scenario: Typing lists the matching lines best first
- **WHEN** the user types `hello`
- **THEN** the rows run from the line that starts with the query on the shorter path to the line holding it later

#### Scenario: No line matches
- **WHEN** the user types a text no line holds in order
- **THEN** the float reads `No match`

### Requirement: The rows are capped and the title says so
At most 200 rows SHALL be kept, and the title SHALL show the kept count followed by `+` when more lines matched.

#### Scenario: The rows are capped and the title says so
- **WHEN** 250 lines match
- **THEN** 200 rows are kept and the title reads `Grep 200+/250`

### Requirement: Rows are shown safely
A row SHALL show each control character as a space and each byte of invalid UTF-8 as a question mark, and a CRLF line SHALL show without its carriage return.

#### Scenario: Lines are shown safely
- **WHEN** a matching line holds an escape character, a bell, or the bytes FF and FE
- **THEN** the row holds spaces and question marks in their place

### Requirement: Picking a row opens the file at its line and column
Enter SHALL open the highlighted row's file in the editing window, and the finder's split, vertical split, and tab keys SHALL open it in a horizontal split, a vertical split, or a tab, each with the cursor on the row's line and at the column, counted in characters, of the line's first byte equal to the query's first byte. With no row Enter SHALL keep the prompt open, and Esc SHALL open nothing.

#### Scenario: Picking a row opens the file at its line and column
- **WHEN** the user types `x = 1` and presses Enter on a line `café x = 1`
- **THEN** that file is open with the cursor on its first line at column 5

#### Scenario: The split, vertical split, and tab picks open at the line
- **WHEN** the user picks a row with the split, vertical split, or tab key
- **THEN** the file opens in a split, a vertical split, or a tab with the cursor on the row's line
