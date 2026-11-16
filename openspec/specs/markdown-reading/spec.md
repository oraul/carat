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
Escape sequences and control characters in the file SHALL be dropped from the reading view. At most 262,144 bytes of the file SHALL be read and at most 10,000 rows kept.

#### Scenario: Hostile text in a Markdown file
- **WHEN** the Markdown file holds escape sequences and control characters
- **THEN** the reading view holds no escape byte and no control character

#### Scenario: An over-cap document
- **WHEN** the Markdown file holds a megabyte of text
- **THEN** the reading view holds at most 10,000 rows and at most 262,144 bytes of the file's text
