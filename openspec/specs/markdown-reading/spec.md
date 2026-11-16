# markdown-reading Specification

## Purpose
Show a Markdown file in its window as reading text, headings, lists, quotes, and code laid out and styled at a readable measure, within the icon set and bounded, and back to the file with one key.

## Requirements

### Requirement: The reading toggle shows a Markdown buffer as reading text
In normal mode `<leader>dr` (`docs.toggle_reading`) SHALL, in a window showing a buffer whose path ends in `.md` or `.markdown`, show in that window a scratch buffer titled `[reading] PATH` holding the file laid out as the documentation float lays out markdown, with the same styles, every row at most the window's width and at most 80 columns. A buffer that is not Markdown SHALL be refused with the message `Not a Markdown buffer` and nothing else changes.

#### Scenario: Toggling a Markdown buffer into the reading view
- **WHEN** a window shows `notes.md` holding a heading, a paragraph, a list, a quote, and a fenced block, and `<leader>dr` is typed
- **THEN** the window shows `[reading] notes.md` with the heading's text, the paragraph without markers, bullet rows, bar rows, and the code indented by two columns, no row wider than 80 columns

#### Scenario: A buffer that is not Markdown
- **WHEN** a window shows `main.rb` and `<leader>dr` is typed
- **THEN** the message reads `Not a Markdown buffer` and the window still shows `main.rb`

### Requirement: The reading toggle returns to the file
Pressed in the reading view, `<leader>dr` SHALL show the file again in the window, with its cursor where it was before the reading view showed.

#### Scenario: Toggling back to the source
- **WHEN** the reading view of `notes.md` shows and `<leader>dr` is typed
- **THEN** the window shows `notes.md` again with the cursor where it was before the first toggle

### Requirement: The reading view keeps to the icon set
The reading view SHALL draw its bullet, quote bar, and rule from the icon set: with `option.icons ascii` they SHALL be `* `, `| `, and a row of `-`, so a document of ASCII text reads as ASCII only.

#### Scenario: The ascii set draws plain characters
- **WHEN** `option.icons ascii` is set and the reading view of an ASCII document with a list, a nested quote, and a thematic break shows
- **THEN** its rows hold no character above code point 127 and no box-drawing cell

### Requirement: The reading view is untrusted and bounded
Escape sequences and control characters in the file SHALL be dropped from the reading view. At most 262,144 bytes of the file SHALL be read and at most 10,000 rows kept; a line crossing that cap SHALL be read only up to it.

#### Scenario: Hostile text in a Markdown file
- **WHEN** the Markdown file holds escape sequences and control characters
- **THEN** the reading view holds no escape byte and no control character

#### Scenario: An over-cap document
- **WHEN** the Markdown file holds a megabyte of text
- **THEN** the reading view holds at most 10,000 rows and at most 262,144 bytes of the file's text

#### Scenario: An over-cap line
- **WHEN** the Markdown file holds one line longer than 262,144 bytes
- **THEN** at most 262,144 bytes of that line are gathered for the reading view, cut on a character boundary

### Requirement: The reading view draws tables aligned in borders
A Markdown table (a header row holding `|`, a separator row of `-` cells with an optional `:` at either end, and the rows holding `|` after it) SHALL show in the reading view as columns inside borders, the header parted from the body by a rule, with no separator row and no source pipe. Each column SHALL be aligned as its separator cell says: `---` or `:--` left, `:-:` center, `--:` right. With `option.icons ascii` the borders SHALL be drawn with `+`, `-`, and `|` only.

#### Scenario: A three-column table at 100 columns
- **WHEN** the reading view of a Markdown file holding a three-column table with a left, a center, and a right aligned column shows in a 100-column window
- **THEN** the table reads as bordered rows of equal width, each cell aligned as its column says, with no separator row and no source pipe

#### Scenario: A table under ascii
- **WHEN** `option.icons ascii` is set and the reading view of a Markdown file holding a table shows
- **THEN** the table's borders are drawn with `+`, `-`, and `|` and no row holds a box-drawing character

### Requirement: A table wider than the measure wraps its cells
When a table at its natural width is wider than the reading view's measure, its columns SHALL be narrowed, the widest first, and their cells wrapped onto further lines of their row, so that no row is wider than the measure and every row keeps its borders and its columns' alignment.

#### Scenario: A three-column table wider than 60 columns
- **WHEN** a three-column table with a left, a center, and a right aligned column, wider than 60 columns, shows in the reading view of a 60-column window
- **THEN** no row is wider than 60 columns, the long cells wrap onto further lines of their row, and every row keeps its borders and its column alignment
