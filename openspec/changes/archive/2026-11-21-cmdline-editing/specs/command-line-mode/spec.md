## MODIFIED Requirements

### Requirement: The command line is edited with typed keys
In command-line mode printable keys SHALL insert at the cursor of the command line, Backspace SHALL remove the character before the cursor, Backspace on an empty command line SHALL return to normal mode, and Escape SHALL discard the command line and return to normal mode.

#### Scenario: Typing and correcting
- **WHEN** ":", "w", "x", Backspace are pressed
- **THEN** the bottom row shows ":w"

#### Scenario: Backspace on empty leaves
- **WHEN** ":" then Backspace are pressed
- **THEN** the mode is normal and the bottom row is empty

#### Scenario: Escape discards
- **WHEN** ":", "w", Escape are pressed on a modified buffer
- **THEN** the mode is normal and no file is written

## ADDED Requirements

### Requirement: The command line has a cursor
The command line, the `/` and `?` prompts, the command palette's prompt, and a plugin's prompt SHALL keep a cursor between two characters of the text, at the end when the line opens and after a recall from the history; a character is a code point, a wide character one move. Typed text SHALL insert at the cursor and leave it after the inserted text.

#### Scenario: Insert in the middle of the line
- **WHEN** ":", "w", "q", `<Left>`, "a", "b" are pressed
- **THEN** the bottom row shows ":wabq" and the cursor is after "wab"

#### Scenario: The search prompt has the cursor
- **WHEN** "/", "a", "c", `<Left>`, "b" are pressed
- **THEN** the bottom row shows "/abc" and the preview matches "abc"

#### Scenario: Recall puts the cursor at the end
- **WHEN** ":set ft?" is run, then ":", `<Up>`, "x" are pressed
- **THEN** the command line shows "set ft?x"

#### Scenario: Recall then edit
- **WHEN** ":set ft?" is run, then ":", `<Up>`, `<Home>`, `<Del>` are pressed
- **THEN** the command line shows "et ft?"

### Requirement: The cursor moves by character and by word
`<Left>` and `<Right>` SHALL move the cursor one character, `<Home>` and `<C-b>` to the start, `<End>` and `<C-e>` to the end, and `<S-Left>` or `<C-Left>`, and `<S-Right>` or `<C-Right>`, one blank-separated word back or forward, none past either end of the text.

#### Scenario: Left and Right move the cursor
- **WHEN** ":", "a", "b", "c", `<Left>`, `<Left>`, "X" are pressed
- **THEN** the bottom row shows ":aXbc" and `<Right>` then "Y" gives ":aXbYc"

#### Scenario: The cursor stays inside the line
- **WHEN** ":", "a", `<Right>`, `<Left>`, `<Left>`, `<Left>`, "X" are pressed
- **THEN** the bottom row shows ":Xa"

#### Scenario: Home and End
- **WHEN** ":", "b", "c", `<Home>`, "a", `<End>`, "d" are pressed
- **THEN** the bottom row shows ":abcd"

#### Scenario: Control-b and Control-e
- **WHEN** ":", "b", "c", `<C-b>`, "a", `<C-e>`, "d" are pressed
- **THEN** the bottom row shows ":abcd"

#### Scenario: Words move by blank-separated word
- **WHEN** ":", "e a/b.rb c", `<S-Left>`, `<C-Left>`, "X" are pressed
- **THEN** the bottom row shows ":e Xa/b.rb c", and with `<Home>`, `<C-Right>`, `<S-Right>`, "Y" instead it shows ":e a/b.rb Yc"

#### Scenario: Movement over multi-byte and wide text
- **WHEN** ":", "é", "日", "z", `<Left>`, `<Left>`, "X" are pressed
- **THEN** the bottom row shows ":éX日z", and with one `<Left>` it shows ":é日Xz"

### Requirement: The cursor is drawn as the bar at its cell
The terminal cursor of the command line SHALL be the bar at the display column of the prompt's width plus the width of the text before the cursor, a wide character counting two cells.

#### Scenario: The bar is at the cursor cell
- **WHEN** ":", "a", "b", `<Left>` are pressed
- **THEN** the cursor is the bar at column 2, after the ":" and the "a"

#### Scenario: The bar counts wide characters and the prompt
- **WHEN** a plugin prompt with the text "Rename to: " holds "日" and "a" and the cursor is between them
- **THEN** the cursor column is the width of the prompt plus the two cells of the wide character

### Requirement: Backspace and Delete remove one character
`<BS>` SHALL remove the character before the cursor and do nothing at the start of a non-empty line; `<Del>` SHALL remove the character under the cursor, and at the end of the line act as `<BS>`. A search prompt SHALL preview its pattern again after each change.

#### Scenario: Backspace removes before the cursor
- **WHEN** ":", "a", "b", "c", `<Left>`, `<BS>` are pressed
- **THEN** the bottom row shows ":ac"

#### Scenario: Backspace at the start does nothing
- **WHEN** ":", "a", `<Home>`, `<BS>` are pressed
- **THEN** the mode is cmdline and the bottom row shows ":a"

#### Scenario: Delete removes the character under the cursor
- **WHEN** ":", "a", "b", "c", `<Home>`, `<Del>` are pressed
- **THEN** the bottom row shows ":bc"

#### Scenario: Delete at the end acts as Backspace
- **WHEN** ":", "a", "b", `<Del>` are pressed
- **THEN** the bottom row shows ":a", and `<Del>` on an empty line returns to normal mode

#### Scenario: The search prompt previews after a deletion
- **WHEN** "/", "a", "c", "b", `<Left>`, `<BS>` are pressed
- **THEN** the bottom row shows "/ab" and the preview matches "ab"

### Requirement: Control-w and Control-u remove a word and a line
`<C-w>` SHALL remove the word before the cursor, skipping blanks first and then one run of word characters or one run of other non-blank characters; `<C-u>` SHALL remove everything before the cursor; both SHALL do nothing on an empty line.

#### Scenario: Control-w removes the word before the cursor
- **WHEN** ":", "e app/models" are typed and `<C-w>` is pressed four times
- **THEN** the bottom row shows ":e app/", then ":e app", then ":e ", then ":"

#### Scenario: Control-w works at the cursor in the middle
- **WHEN** ":", "ab cd", `<Left>`, `<Left>`, `<C-w>` are pressed
- **THEN** the bottom row shows ":cd" with the cursor at its start

#### Scenario: Control-u removes everything before the cursor
- **WHEN** ":", "abcd", `<Left>`, `<Left>`, `<C-u>` are pressed
- **THEN** the bottom row shows ":cd" with the cursor at its start

#### Scenario: Control-w and Control-u on an empty line do nothing
- **WHEN** ":", `<C-w>`, `<C-u>` are pressed
- **THEN** the mode is cmdline and the bottom row shows ":"
