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

### Requirement: The language server is the editor's completion source
When the current buffer's language server runs and advertised a completion provider, typing a word in insert mode SHALL ask that server for the word's completions without making any key wait: the request SHALL be sent at an idle tick once no other word was wanted for 0.1 seconds, after the server was told the buffer's text, and the popup SHALL fill from the answer when it arrives, with no key pressed. With no completing server, typing SHALL behave and cost as without completion.

#### Scenario: The answer fills the popup with no key
- **WHEN** ruby-lsp completes, "fi" is typed in a Ruby buffer, the editor stays idle, and the server answers "file_name", "filter", and "final"
- **THEN** the popup shows all three, "final" first, without another key

#### Scenario: An answer between keys
- **WHEN** a completion request is in flight and its answer arrives 0.1 seconds after a key, before the next key
- **THEN** the popup shows before the next key is read

#### Scenario: Requests are debounced
- **WHEN** "a b c" is typed with less than 0.1 seconds between the words
- **THEN** one completion request is sent, for the word "c"

#### Scenario: No completing server
- **WHEN** the server advertised no completion provider and "fi" is typed
- **THEN** no completion request is sent and no popup shows

### Requirement: A completion answer serves only the word it was asked for
A server's answer SHALL serve only a word at the same start that begins with the typed part the request was sent for; another word typed there later, or a word whose request was never sent or never answered, SHALL be asked again.

#### Scenario: Another word at the same start asks again
- **WHEN** "fi" was answered, deleted with backspace, and "ba" is typed at the same column
- **THEN** a second completion request is sent and its answer fills the popup

#### Scenario: A word deleted within the debounce asks nothing
- **WHEN** "x" is typed and deleted with backspace within 0.1 seconds, then "fi" is typed at the same column
- **THEN** no completion request is sent for the empty text, and one request is sent for "fi" whose answer fills the popup

#### Scenario: A request skipped by leaving insert mode
- **WHEN** "fi" is typed and Esc pressed within 0.1 seconds, then insert mode is entered again and "l" typed
- **THEN** a completion request is sent for the word

### Requirement: A stale completion request is cancelled
When another word is wanted while a completion request is in flight, the editor SHALL send `$/cancelRequest` for it and SHALL drop its answer; an answer to no request in flight SHALL change nothing.

#### Scenario: Typing another word cancels
- **WHEN** a request for "fi" is in flight and " ba" is typed
- **THEN** a cancel for the first request is sent and its answer, when it arrives, opens no popup

### Requirement: A server's completions are bounded and untrusted
The editor SHALL read at most 200 items of an answer, and SHALL drop escape sequences and controls from each label, detail, and insert text and cut them to their limits before keeping them; an item without a string label SHALL be skipped and an unknown kind SHALL read as text.

#### Scenario: An escape-laden, oversized item
- **WHEN** the server answers an item whose label holds an escape sequence and is 5,000 bytes long
- **THEN** the popup's label holds no escape character and is at most 80 bytes

#### Scenario: Too many items
- **WHEN** the server answers 300 items
- **THEN** 200 are kept

### Requirement: The selected item's documentation shows beside the popup
While the completion popup shows and its selected item has documentation, the editor SHALL show that documentation in a float beside the popup: at the popup's rows, on its right, or on its left when the screen lacks the room on the right, at most 60 columns wide with longer lines wrapped and at most 12 rows high. The float SHALL follow the selection and the popup's place, and SHALL close whenever the popup closes. An item without documentation SHALL show no documentation float.

#### Scenario: Documentation beside the selected item
- **WHEN** the source documents "final" as "Ends the block." and "fi" is typed in insert mode
- **THEN** the popup selects "final" and a float on the popup's right shows "Ends the block."

#### Scenario: The float follows the selection
- **WHEN** the float shows "final"'s documentation and Ctrl-N selects "filter", which has none
- **THEN** no documentation float shows

#### Scenario: The float closes with the popup
- **WHEN** the documentation float shows and Esc, Enter, or a space is typed
- **THEN** no float shows

#### Scenario: No room on the right
- **WHEN** the popup stands near the screen's right edge
- **THEN** the documentation float stands on the popup's left

#### Scenario: Long documentation
- **WHEN** an item's documentation is one paragraph of 300 characters
- **THEN** the float is at most 60 columns wide and shows the paragraph wrapped at word boundaries

### Requirement: Documentation is fetched lazily when the selection settles
When an item's documentation was not in the completion answer and the server advertised `resolveProvider`, the editor SHALL send `completionItem/resolve` with the item as the server gave it once the selection has stayed on the item for 0.1 seconds, without making any key wait, and SHALL show the answer's documentation at the next idle tick with no key pressed. Items the selection passes over within 0.1 seconds SHALL be asked nothing.

#### Scenario: One request for the settled item
- **WHEN** a server with `resolveProvider` answers "file_name", "filter", and "final" without documentation, Ctrl-N is pressed twice quickly, and the editor stays idle
- **THEN** one `completionItem/resolve` is sent, for the item now selected, and its documentation shows when the answer arrives

### Requirement: At most one documentation request per item
The editor SHALL send at most one `completionItem/resolve` per item of an answer and have at most one in flight. An item documented in the answer, or a server without `resolveProvider`, SHALL be asked nothing. A resolve answer that is not for the request in flight, or for a list since replaced, SHALL change nothing.

#### Scenario: Returning to a resolved item
- **WHEN** an item's documentation was resolved, the selection moves away and back, and the editor stays idle
- **THEN** no second request is sent and its documentation shows again

#### Scenario: Documentation in the answer
- **WHEN** the completion answer carries an item's documentation
- **THEN** the documentation shows and no `completionItem/resolve` is sent

#### Scenario: A server that does not resolve
- **WHEN** the server advertised no `resolveProvider` and its items carry no documentation
- **THEN** no `completionItem/resolve` is sent and no documentation float shows

### Requirement: Documentation markdown reads as plain text
The documentation SHALL be shown as plain text: heading markers, emphasis markers, inline code backticks, and link and image markup SHALL be taken out with their text kept; a list item's marker SHALL read as a bullet; a block quote's markers as bars; fenced code SHALL show its lines indented by two spaces without its fences; runs of blank lines SHALL read as one.

#### Scenario: Markup taken out
- **WHEN** the documentation is "# Title\n\nUse **`map`** or [each](#each).\n\n- one\n\n```ruby\nx = 1\n```"
- **THEN** the float shows "Title", "", "Use map or each.", "", "• one", "", "  x = 1"

### Requirement: Documentation text is untrusted and bounded
The documentation SHALL drop whole escape sequences and every other control, show illegal bytes as U+FFFD, read at most 16,384 bytes of a document, keep at most 100 rows, and cap block quote and list nesting at four levels.

#### Scenario: An escape-laden document
- **WHEN** an item's documentation holds "\e[31mred\e[0m\e]0;title\a"
- **THEN** the float shows "red" and no escape character reaches the screen

#### Scenario: Deep nesting
- **WHEN** the documentation is a line of 10,000 ">" followed by "x"
- **THEN** the row shows four bars and "x"

#### Scenario: An oversized document
- **WHEN** the documentation is a megabyte of short lines
- **THEN** at most 100 rows are kept
