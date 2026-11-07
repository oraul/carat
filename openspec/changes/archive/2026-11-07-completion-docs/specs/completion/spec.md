## ADDED Requirements

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
