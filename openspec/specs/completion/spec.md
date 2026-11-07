# completion Specification

## Purpose
Completion as you type in insert mode: a popup of the candidates a completion source gives for the word before the cursor, matched fuzzily, moved through and accepted with keys, its text made safe and bounded.

## Requirements

### Requirement: Typing a word opens the completion popup
In insert mode, typing a character SHALL, when the completion source is ready for the buffer and the cursor follows word characters (ASCII letters, digits, underscore, or any non-ASCII character), show the source's candidates for that word that match the typed part in a popup of at most ten rows, the first selected. With no match or no ready source, no popup SHALL show and the key SHALL behave and cost as without completion.

#### Scenario: Typing opens the popup
- **WHEN** the source holds "file_name", "filter", and "final", and "fi" is typed after i on an empty line
- **THEN** a popup under the line shows all three, "final" first and selected

#### Scenario: A source that is not ready
- **WHEN** the source holds nothing and "fi" is typed
- **THEN** no popup shows and the line reads "fi"

### Requirement: The popup stands below the word or above it
The popup SHALL stand below the cursor's row, its labels under the word's first character, or above the row when fewer rows are free below than the popup needs and more are free above.

#### Scenario: Above the word at the bottom of the screen
- **WHEN** the cursor is on the last text row and the popup opens
- **THEN** the popup's rows end on the row above the cursor

### Requirement: A row shows the kind icon, the label, and the detail
Each row SHALL show the icon of the candidate's kind, looked up by the name `kind_<kind>` in the icons option's set, a space, the label, and the detail or type aligned in a column on the right; the selected row SHALL be drawn in `PmenuSel` and the others in `Pmenu`. A label or detail wider than its column SHALL be cut at a character boundary.

#### Scenario: A row's cells
- **WHEN** the popup shows "file_name" of kind "variable" with detail "String" with the ascii icons
- **THEN** its row reads " v file_name  String " and carries `PmenuSel`

### Requirement: Matching is fuzzy over the word's parts
The typed part SHALL be cut at underscores into parts. A candidate SHALL match when each part's first letter starts a part of the candidate (its first character, one after a non-word character, or an uppercase letter after a lowercase one) later than the previous part's start, and the part's other letters follow in order; ASCII letters SHALL match ignoring case.

#### Scenario: Parts anchored in order
- **WHEN** "fn_na" is matched against "file_name", "fn_name", "final", and "name"
- **THEN** "file_name" and "fn_name" match and "final" and "name" do not

#### Scenario: A part starting mid-word does not match
- **WHEN** "ame" is matched against "file_name"
- **THEN** it does not match

#### Scenario: Case changes start parts
- **WHEN** "gn" is matched against "getName"
- **THEN** it matches

### Requirement: Matches are ordered by prefix and score
Candidates whose label starts with the typed text SHALL come first, then those with more letters matched in runs, then shorter labels, then the source's order.

#### Scenario: Prefix first
- **WHEN** "fil" is typed and the source holds "a_file_list" and "file" in that order
- **THEN** "file" is the first row

### Requirement: Keys move, accept, and close while the popup shows
While the popup shows, a key SHALL be looked up first in the `keymap.completion` bindings, any other key going to insert mode's. By default Ctrl-N and Down SHALL select the next row, Ctrl-P and Up the previous one, wrapping; Enter SHALL replace the typed part with the selected item's text, Tab the whole word under the cursor; Esc SHALL close the popup and stay in insert mode. Accepting SHALL close the popup, the cursor after the text.

#### Scenario: Enter inserts
- **WHEN** the line reads "fi_tail" with the cursor after "fi", "file_name" is selected, and Enter is pressed
- **THEN** the line reads "file_name_tail", the cursor follows "file_name", and the popup is closed

#### Scenario: Tab replaces the word
- **WHEN** the line reads "fi_tail" with the cursor after "fi", "file_name" is selected, and Tab is pressed
- **THEN** the line reads "file_name"

#### Scenario: Ctrl-N, Ctrl-P, and the arrows move
- **WHEN** the popup shows three rows and Ctrl-N, Down, Ctrl-N, Ctrl-P, and Up are pressed in turn
- **THEN** the selection is on rows 2, 3, 1, 3, and 2 after each key

#### Scenario: Esc closes
- **WHEN** Esc is pressed while the popup shows
- **THEN** the popup closes and the mode is still insert; a second Esc leaves insert mode

#### Scenario: Keys without a popup are unchanged
- **WHEN** no popup shows and Enter is pressed in insert mode
- **THEN** the line is split as before

### Requirement: The popup follows the typed part
While the popup shows, typing or erasing in the word SHALL filter the candidates again from those the source gave for the word, closing the popup when none matches or the word before the cursor is empty; moving to another line, another buffer, or out of insert mode SHALL close it.

#### Scenario: Typing narrows
- **WHEN** the popup shows "final", "filter", and "file_name" for "fi" and "l" then "e" are typed
- **THEN** after "e" "file_name" is first and "final" no longer shows

#### Scenario: A non-word character closes
- **WHEN** the popup shows and a space is typed
- **THEN** the popup closes

#### Scenario: Moving to another row closes
- **WHEN** the popup shows for "fi" on the first line and a cursor key bound in insert mode moves the cursor to the second line, after another "fi"
- **THEN** the popup closes and the source is not asked again

#### Scenario: Switching to another buffer closes
- **WHEN** the popup shows and a key bound in insert mode switches to another buffer whose cursor follows a word
- **THEN** the popup closes

### Requirement: An accepted item belongs to the insert session
An accepted item SHALL be part of the insert session: undo SHALL remove the typed text and the item together, the dot command SHALL repeat the session with the item's text, and the `.` register SHALL hold the text as it reads after the item.

#### Scenario: Undo and repeat
- **WHEN** "ofi" is typed, "file_name" accepted with Enter, Esc pressed, then "j." and "u" are used
- **THEN** "j." adds a line "file_name" below the next line and "u" removes it

#### Scenario: The dot register
- **WHEN** "ifi", Enter on "file_name", and Esc are typed
- **THEN** the `.` register holds "file_name"

### Requirement: Completion text is untrusted
Every label, detail, and insert text from the source SHALL drop whole escape sequences (CSI, OSC and other strings to their terminator, two-character escapes, the C1 forms) and then every other control, with breaks and tabs as spaces and illegal bytes as U+FFFD. A kind outside the known names SHALL read as text.

#### Scenario: An escape-laden label
- **WHEN** the source gives the label "\e[31mred\e[0m\e]0;title\a_x"
- **THEN** the row shows "red_x"

### Requirement: Completion text and lists are bounded
A label or a detail SHALL be cut at a character boundary to at most 80 bytes and an insert text to 200 bytes, and at most 200 candidates of a source's list SHALL be kept.

#### Scenario: An oversized label
- **WHEN** the source gives a label of 500 letters
- **THEN** the label kept is 80 bytes long

#### Scenario: Too many candidates
- **WHEN** the source gives 300 candidates that all match
- **THEN** 200 are kept
