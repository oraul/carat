## ADDED Requirements

### Requirement: Matching lines rank by whole words, then hits, then path
Rows SHALL rank by the terms found as a whole word, a term holding a word start before it and a word end after it, more such terms first; then by more hits of the terms in the line; then by a shorter path; then by listing order.

#### Scenario: A whole-word hit ranks above a part-word hit
- **WHEN** the user types `explorer` and one line holds it as a whole word once while a line on a shorter path holds it three times inside longer words
- **THEN** the whole-word line is listed first

## MODIFIED Requirements

### Requirement: The picker reads the finder's files once and within bounds
The picker's files SHALL be the finder's listing, each read once when the picker opens. A file that cannot be read, holds a NUL byte, or is over the host's read limit SHALL add no line; only its first 1000 lines SHALL be stored, a line SHALL be cut at the last character boundary at or under 400 bytes, and at most 400,000 lines SHALL be stored.

#### Scenario: The picker stores only bounded lines of each file
- **WHEN** a file holds 1200 lines, a line holds 500 bytes, a line holds a multi-byte character the cut would split, or more than 400,000 lines are stored
- **THEN** only the first 1000 lines of the file are stored, the line is cut at a character boundary at or under 400 bytes, and the title marks the store cap with `+`

#### Scenario: A tree the size of this repository is searched whole
- **WHEN** the project holds 150,001 lines in files of at most 1000 lines each
- **THEN** every line is stored and the title's stored count has no `+`

#### Scenario: Files that cannot be searched are left out
- **WHEN** the project holds a binary file, a file over the read limit, an empty file, and an ignored directory
- **THEN** none of them adds a line to the count or a row

### Requirement: Typing lists the matching lines best first
Every change of the typed text SHALL list again the lines that hold every term of the text as a substring, in any order, ignoring ASCII case; the terms are the runs of bytes between spaces, and a text with no term lists nothing. Each row SHALL show the file's path, the line number, and the line's text. With no match the float SHALL read `No match`. Letters that appear in order but not together SHALL NOT match.

#### Scenario: Typing lists the matching lines best first
- **WHEN** the user types `hello`
- **THEN** the rows run from the line holding it as a whole word on the shorter path to the lines on longer paths, equal paths in listing order

#### Scenario: Scattered letters do not match
- **WHEN** the user types `wrt` and no line holds those three bytes together
- **THEN** the float reads `No match`

#### Scenario: Two terms match in any order
- **WHEN** the user types `open explorer` or `explorer open` and a line reads `explorer open`
- **THEN** the line is listed for both, and a line holding only one of the terms is not listed

#### Scenario: Case is ignored in the query
- **WHEN** the user types `EXPLORER`
- **THEN** the same rows are listed as for `explorer`

#### Scenario: A query of only spaces lists nothing
- **WHEN** the user types spaces only
- **THEN** the float reads `Type to search the files' lines`

#### Scenario: No line matches
- **WHEN** the user types a text no line holds
- **THEN** the float reads `No match`

### Requirement: Picking a row opens the file at its line and column
Enter SHALL open the highlighted row's file in the editing window, and the finder's split, vertical split, and tab keys SHALL open it in a horizontal split, a vertical split, or a tab, each with the cursor on the row's line and at the column, counted in characters, of the first byte of the first hit of the query's first term in the line. With no row Enter SHALL keep the prompt open, and Esc SHALL open nothing.

#### Scenario: Picking a row opens the file at its line and column
- **WHEN** the user types `x = 1` and presses Enter on a line `café x = 1`
- **THEN** that file is open with the cursor on its first line at column 5

#### Scenario: The column is the first byte of the first term's hit
- **WHEN** the user types `explorer` and picks a line `e x p l o r e r and later Explorer here`, or types `open explorer` and picks `explorer open`
- **THEN** the cursor is at column 26 of the first line, and at column 9 of the second

#### Scenario: The split, vertical split, and tab picks open at the line
- **WHEN** the user picks a row with the split, vertical split, or tab key
- **THEN** the file opens in a split, a vertical split, or a tab with the cursor on the row's line
