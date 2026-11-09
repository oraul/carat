## ADDED Requirements

### Requirement: Ctrl-N and Ctrl-P complete a word from the open buffers
In insert mode with no completion popup showing, Ctrl-N and Ctrl-P SHALL complete the word before the cursor from the words of the listed buffers, without a language server, and show the matches in the completion popup, whose keys then apply. With no match the message row SHALL read "Pattern not found" as an error.

#### Scenario: Repeated presses move and wrap
- **WHEN** Ctrl-N opened a popup of three words and Ctrl-N is pressed three more times
- **THEN** the selection is on rows 2, 3, and 1 after each press

#### Scenario: Enter puts the word over the typed part
- **WHEN** Ctrl-N selected "file" after the typed "fi" and Enter is pressed
- **THEN** the line reads "file", the cursor after it, the popup closed, and the mode still insert

#### Scenario: No match
- **WHEN** no word of the listed buffers starts with the typed "zq" and Ctrl-N is pressed
- **THEN** no popup opens, the text is unchanged, the mode is insert, and the message row reads "Pattern not found" as an error

#### Scenario: The server's popup keeps its keys
- **WHEN** the language server's popup shows and Ctrl-N is pressed
- **THEN** its selection moves to the next row and no word completion runs

### Requirement: A keyword match starts with the typed part
A word SHALL be a run of ASCII letters, digits, underscores, and bytes of 0x80 or more. A match SHALL start with the typed part, case sensitive, be longer than it, and not be the word being completed; each match SHALL be listed once, where it is first found. With no word before the cursor every word SHALL be a match.

#### Scenario: Duplicates are listed once
- **WHEN** the buffer holds "file" three times and "final" once after the typed "fi" and Ctrl-N is pressed
- **THEN** the popup shows "file" and "final", once each

#### Scenario: Case counts
- **WHEN** the buffer holds "File" and "file" and Ctrl-N is pressed after the typed "fi"
- **THEN** the popup shows "file" only

### Requirement: Ctrl-N scans forward from the cursor
Ctrl-N SHALL scan the current buffer forward from the cursor (the rest of the cursor's line, the lines below, then from the first line down to the cursor), then every other listed file buffer after it in list order, top to bottom, and select the first match.

#### Scenario: Ctrl-N selects the nearest match forward
- **WHEN** the buffer reads "alpha", "fi", "file", "final", "filter" with the cursor after "fi" on the second line in insert mode and Ctrl-N is pressed
- **THEN** the popup shows "file", "final", "filter" in that order, "file" selected, and the text is unchanged

#### Scenario: The forward scan wraps to the top
- **WHEN** the buffer reads "fine", "fi", "file" with the cursor after "fi" on the second line and Ctrl-N is pressed
- **THEN** the popup shows "file" then "fine"

#### Scenario: Other listed buffers follow the current one
- **WHEN** the current buffer holds "fi" and "file", another listed buffer holds "final", and Ctrl-N is pressed after "fi"
- **THEN** the popup shows "file" before "final"

### Requirement: Ctrl-P scans backward from the cursor
Ctrl-P SHALL scan the current buffer backward from the cursor (the line before the cursor, the lines above, then from the last line up to the cursor), then the other listed file buffers in list order, each bottom to top, list the matches with the nearest one last, and select it.

#### Scenario: Ctrl-P selects the nearest match backward
- **WHEN** the buffer reads "first", "fine", "fi", "file" with the cursor after "fi" on the third line and Ctrl-P is pressed
- **THEN** the popup shows "file", "first", "fine" in that order, "fine" selected on the last row

### Requirement: Keyword completion is bounded and costs nothing until asked
A press SHALL read at most 1,000,000 bytes of text and keep at most 200 matches. Typing without a popup SHALL scan no buffer.

#### Scenario: A large buffer is scanned within the bound
- **WHEN** a match lies past 1,000,000 bytes of text after the cursor and Ctrl-N is pressed
- **THEN** that match is not offered, while a match before the bound is

#### Scenario: Typing costs nothing more
- **WHEN** characters are typed in insert mode with no popup showing
- **THEN** no buffer is scanned and each key allocates as before
