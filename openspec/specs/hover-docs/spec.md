# hover-docs Specification

## Purpose
The documentation of the symbol under the cursor, asked of the buffer's language server with `K`, shown in a float the user can scroll, pin into a split, and close, its untrusted text bounded.

## Requirements

### Requirement: K asks the language server for the documentation under the cursor
In normal mode `K` SHALL ask the running language server of the current buffer's file type for the hover documentation at the cursor, without waiting: the answer SHALL open the documentation float at the next idle moment with no key pressed. When the buffer has no path or no running server of its file type advertised hover, `K` SHALL show `No hover provider for this buffer` and ask nothing.

#### Scenario: The answer opens a float with no key
- **WHEN** a hovering server runs for a Ruby buffer, `K` is typed on a word, and the server answers with markdown
- **THEN** a bordered float below the cursor shows the documentation, before any other key

#### Scenario: No server hovers
- **WHEN** `K` is typed in a buffer whose server does not advertise hover
- **THEN** `No hover provider for this buffer` is shown and no request is sent

### Requirement: A hover answer is read only while it still applies
An answer with no contents, or an error, SHALL show `No information available`. A new `K` SHALL cancel the request in flight, and a request unanswered two seconds after it was sent SHALL be cancelled with no message. An answer that arrives after the cursor moved, the window or buffer changed, or normal mode was left SHALL be dropped.

#### Scenario: An empty answer
- **WHEN** the server answers the hover request with null
- **THEN** `No information available` is shown and no float opens

#### Scenario: A stale answer
- **WHEN** `K` is typed, then `l` moves the cursor before the answer arrives
- **THEN** the answer opens no float

#### Scenario: An unanswered request
- **WHEN** the server does not answer within two seconds
- **THEN** the request is cancelled and the editor waits on it no more

### Requirement: The documentation float shows markdown as rows
The float SHALL show the markdown laid out as rows: heading markers, emphasis, code span backticks, and link markup taken out, list markers as bullets, block quotes as bars, and fenced code indented by two columns. Each row SHALL be at most 80 columns and within the screen, longer lines wrapped at a space and never broken inside their own indent, bullet, or bars. The float SHALL be at most 20 rows high, bordered, below the cursor or above it when only above has the room.

#### Scenario: Markup laid out
- **WHEN** the answer is a heading, a paragraph with `**strong**` and `` `code` ``, a list, and a fenced block
- **THEN** the float shows the heading's text, the paragraph without markers, bullet rows, and the code indented by two columns

#### Scenario: A wrapped bullet keeps its bullet with its text
- **WHEN** a bullet row holds one word wider than the float
- **THEN** the bullet and the start of the word share the first row

### Requirement: The documentation text is untrusted and bounded
Escape sequences and control characters of the documentation SHALL never reach the screen; at most 16,384 bytes SHALL be read, at most 100 rows kept, quote and list nesting capped at four levels, and a list of contents read up to 16 parts. No answer SHALL crash or stall the editor.

#### Scenario: Hostile text
- **WHEN** the answer holds escape sequences, a megabyte of text, and quotes nested ten deep
- **THEN** no escape reaches the screen, the float holds at most 100 rows, and at most four bars lead a row

### Requirement: The documentation float scrolls and closes
While the documentation float shows, `K` SHALL enter it, so normal-mode motions and scrolling keys move through the documentation, `Esc` and `:q` closing it. The float SHALL close when, in the window under it, the cursor moves, the buffer or the window changes, or normal mode is left; keys inside the entered float SHALL not close it. While no documentation float shows, a key SHALL do no work for it beyond one comparison.

#### Scenario: A long document scrolls
- **WHEN** the documentation has more rows than the float, `K` is typed again and then `G`
- **THEN** the float shows the document's last row

#### Scenario: Moving the cursor closes the float
- **WHEN** the documentation float shows and `l` is typed
- **THEN** the float is closed

#### Scenario: Esc closes the float
- **WHEN** the documentation float shows and `Esc` is typed
- **THEN** the float is closed

### Requirement: The pin key keeps the documentation in a split
The pin key SHALL open the shown documentation in a horizontal split over a scratch buffer holding the same rows, close the float, and focus the split; the split SHALL stay when the cursor moves or `Esc` is pressed. With no documentation float the pin key SHALL show `No documentation to pin`.

#### Scenario: Pinning
- **WHEN** the documentation float shows and the pin key is typed, then `Esc` and `j`
- **THEN** a second window shows the documentation's rows, no float is open, and the second window stays

#### Scenario: Nothing to pin
- **WHEN** no documentation float shows and the pin key is typed
- **THEN** `No documentation to pin` is shown and the window count is unchanged

### Requirement: Documentation markup is drawn in its own groups
The documentation float SHALL draw a heading's text in `@markup.heading`, strong text in `@markup.strong`, emphasized text in `@markup.italic`, a code span's text in `@markup.raw`, a link's or an image's text in `@markup.link.label`, and the rows of fenced code in `@markup.raw.block`, each over the float's background. While no documentation float shows, a key SHALL allocate nothing more for the styles.

#### Scenario: Markup in its groups
- **WHEN** the answer is "# Title\n\nUse **map**, *each*, `x`, or [docs](#d)." and the float shows
- **THEN** "Title" is drawn in `@markup.heading`, "map" in `@markup.strong`, "each" in `@markup.italic`, "x" in `@markup.raw`, and "docs" in `@markup.link.label`, and "Use" in NormalFloat

### Requirement: Fenced code of a known language is highlighted
When a fence names a language that an enabled plugin tokenizes and syntax is on, the code's tokens SHALL be drawn in their syntax groups over `@markup.raw.block`, as a buffer of that filetype is highlighted.

#### Scenario: Fenced Ruby through the highlighter
- **WHEN** the answer holds a fenced block opened by "```ruby" with the line "# note" and the float shows
- **THEN** the comment is drawn in Comment over the float's background

#### Scenario: Fenced code of an unknown language
- **WHEN** the answer holds a fenced block opened by "```text" with the line "plain words"
- **THEN** the code is drawn in `@markup.raw.block`

### Requirement: The pinned split keeps the styles and NO_COLOR drops them
The pinned split SHALL draw its rows with the same groups over the window's background. When `NO_COLOR` is set, no markup or token group SHALL be drawn in the float or the pinned split.

#### Scenario: The pinned split keeps the styles
- **WHEN** the float shows a heading and the pin key is typed
- **THEN** the split draws the heading's text in `@markup.heading`

#### Scenario: NO_COLOR draws the documentation plain
- **WHEN** `NO_COLOR` is set and the float shows a heading
- **THEN** the heading's text is drawn in NormalFloat
