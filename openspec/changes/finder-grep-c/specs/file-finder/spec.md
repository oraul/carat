## MODIFIED Requirements

### Requirement: Space f g opens the grep picker
In normal mode `<leader>fg` SHALL open the finder's content picker: the prompt `> ` and a bordered float titled `Grep F of M files, L of N lines` (F files shown in the rows, M files with a matching line, L matching lines, N lines stored), reading `Type to search the files' lines` until text is typed. The key SHALL be a default binding of the plugin, which the configuration may replace, and the action SHALL be listed in the palette.

#### Scenario: Space f g opens the picker
- **WHEN** the user presses `<Space>fg`
- **THEN** the mode is command-line and a float titled `Grep 0 of 0 files, 0 of N lines` reads `Type to search the files' lines`

### Requirement: The rows are capped and the title says so
At most 200 rows SHALL be kept, and the title SHALL count the files the rows show, the files with a matching line, and the matching lines, so a count of lines above 200 shows the cap.

#### Scenario: The rows are capped and the title says so
- **WHEN** 250 lines of one file match
- **THEN** 200 rows are kept and the title reads `Grep 1 of 1 files, 250 of 250 lines`

#### Scenario: The title counts files and lines
- **WHEN** 250 lines of one file and one line of another match
- **THEN** the title reads `Grep 2 of 2 files, 251 of 251 lines`

### Requirement: Rows are shown safely
A row SHALL show each control character, each bidirectional embedding, override, isolate, or mark (U+061C, U+200E, U+200F, U+202A to U+202E, U+2066 to U+2069), each zero-width character (U+200B to U+200D, U+FEFF), and the line and paragraph separators (U+2028, U+2029) as a space and each byte of invalid UTF-8 as a question mark, and a CRLF line SHALL show without its carriage return.

#### Scenario: Lines are shown safely
- **WHEN** a matching line holds an escape character, a bell, or the bytes FF and FE
- **THEN** the row holds spaces and question marks in their place

#### Scenario: Invisible format and separator characters show as spaces
- **WHEN** a matching line holds one of U+061C, U+200B to U+200F, U+2028 to U+202E, U+2066 to U+2069, or U+FEFF
- **THEN** the row holds a space in its place

### Requirement: Matching lines rank by whole words, then hits, then path
Rows SHALL list each matching file's best line before any file's second best line, then every file's second best line before any third, and so on. Within each such round, and among the lines of one file, rows SHALL rank by the terms found as a whole word, a term holding a word start before it and a word end after it, more such terms first; then by more hits of the terms in the line; then by a shorter path; then by listing order, so a file's lines of equal rank keep their line order.

#### Scenario: A whole-word hit ranks above a part-word hit
- **WHEN** the user types `explorer` and one line holds it as a whole word once while a line on a shorter path holds it three times inside longer words
- **THEN** the whole-word line is listed first

#### Scenario: A file with one hit is listed beside a file with more hits than the row cap
- **WHEN** one file holds 250 matching lines and a file on a longer path holds one
- **THEN** the second row is the one-hit file's line, ahead of the first file's second line

#### Scenario: Lines of equal rank keep their order in each file
- **WHEN** two files of equal path length each hold three lines of equal rank
- **THEN** the rows are the first lines of both files in listing order, then their second lines, then their third

### Requirement: The picker reads the finder's files once and within bounds
The picker's files SHALL be the finder's listing, each read once when the picker opens. A file that cannot be read, holds a NUL byte, or is over the host's read limit SHALL add no line; only its first 1000 lines SHALL be stored, a line SHALL be cut at the last character boundary at or under 400 bytes, and at most 400,000 lines SHALL be stored. Each key SHALL search the stored lines within the per-key bound of the requirement Each key searches a bounded number of lines.

#### Scenario: The picker stores only bounded lines of each file
- **WHEN** a file holds 1200 lines, a line holds 500 bytes, a line holds a multi-byte character the cut would split, or more than 400,000 lines are stored
- **THEN** only the first 1000 lines of the file are stored, the line is cut at a character boundary at or under 400 bytes, and the title marks the store cap with `+`

#### Scenario: A tree the size of this repository is searched whole
- **WHEN** the project holds 150,001 lines in files of at most 1000 lines each
- **THEN** every line is stored and the title's stored count has no `+`, a key checks 30,000 of them, and keys that extend the text continue through the rest

#### Scenario: Files that cannot be searched are left out
- **WHEN** the project holds a binary file, a file over the read limit, an empty file, and an ignored directory
- **THEN** none of them adds a line to the count or a row

### Requirement: Typing lists the matching lines best first
Every change of the typed text SHALL list again, among the stored lines the key checks within its per-key bound, the lines that hold every term of the text as a substring, in any order, ignoring ASCII case; the terms are the runs of bytes between spaces, and a text with no term lists nothing. Each row SHALL show the file's path, the line number, and the line's text. With no match the float SHALL read `No match`. Letters that appear in order but not together SHALL NOT match.

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

## ADDED Requirements

### Requirement: Each key searches a bounded number of lines
A key SHALL check at most 30,000 stored lines from where its search starts. When the typed text only extends the previous one, every previous term found inside a new term, the key SHALL check again the lines the previous key matched and continue from the first line it did not check, within 30,000 lines less those it kept; any other text SHALL start again from the first stored line. While stored lines remain unchecked the title SHALL mark the counts of files and of matching lines with `+`.

#### Scenario: A key checks at most 30,000 lines
- **WHEN** the project holds 150,001 lines that all match and the user types `x`
- **THEN** 30,000 lines are checked and the title's counts of files and matching lines carry `+`, the stored count none

#### Scenario: An extended query continues the search
- **WHEN** the project holds 40,000 lines holding `ab` and, after them, one line holding `abc`, and the user types `a`, `b`, then `c`
- **THEN** after `c` the line holding `abc` is the one row and the title carries no `+`

#### Scenario: A backspace starts the search again
- **WHEN** the user then presses Backspace
- **THEN** the search starts from the first line, 30,000 lines are checked, and the counts carry `+`
