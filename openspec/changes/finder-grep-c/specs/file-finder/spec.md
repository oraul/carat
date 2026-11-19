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
A row SHALL show each control character and each bidirectional embedding, override, or isolate character (U+202A to U+202E, U+2066 to U+2069) as a space and each byte of invalid UTF-8 as a question mark, and a CRLF line SHALL show without its carriage return.

#### Scenario: Lines are shown safely
- **WHEN** a matching line holds an escape character, a bell, or the bytes FF and FE
- **THEN** the row holds spaces and question marks in their place

#### Scenario: Bidirectional format characters show as spaces
- **WHEN** a matching line holds one of U+202A to U+202E or U+2066 to U+2069
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
