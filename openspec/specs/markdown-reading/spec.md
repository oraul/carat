# markdown-reading Specification

## Purpose
Show a Markdown file in its window as reading text, headings, lists, quotes, and code laid out and styled at a readable measure, within the icon set and bounded, and back to the file with one key.

## Requirements

### Requirement: The reading toggle shows a Markdown buffer as reading text
In normal mode `<leader>dr` (`docs.toggle_reading`) SHALL, in a window showing a buffer whose path ends in `.md` or `.markdown`, show in that window a scratch buffer titled `[reading] PATH` holding the file laid out as the documentation float lays out markdown, in the same styles, its fenced code framed, every row at most the window's width and at most 80 columns. A buffer that is not Markdown SHALL be refused with the message `Not a Markdown buffer` and nothing else changes.

#### Scenario: Toggling a Markdown buffer into the reading view
- **WHEN** a window shows `notes.md` holding a heading, a paragraph, a list, a quote, and a fenced block, and `<leader>dr` is typed
- **THEN** the window shows `[reading] notes.md` with the heading's text, the paragraph without markers, bullet rows, bar rows, and the code inside a frame, no row wider than 80 columns

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

### Requirement: The reading view flows paragraphs and quotes to the measure
The lines of a paragraph SHALL show in the reading view as one text wrapped at the window's measure, and the lines of a block quote at one depth and indentation as one quote text wrapped at the measure, each later row keeping its bars. A heading, a thematic break, a list item, fenced code, an indented code line, in a quote too, a table, a blank line, or a line ending in two spaces SHALL end the flowing text, and lines of different quote depths SHALL not flow together.

#### Scenario: A two-line paragraph at 60 columns
- **WHEN** the reading view of a Markdown file holding a paragraph written on two short lines shows in a 60-column window
- **THEN** the paragraph reads as one row holding both lines' words parted by one space

#### Scenario: A two-line quote at 60 columns
- **WHEN** the reading view of a Markdown file holding a block quote written on two short `>` lines shows in a 60-column window
- **THEN** the quote reads as one row behind one bar holding both lines' words parted by one space

#### Scenario: A flowed quote wider than the measure
- **WHEN** the reading view of a Markdown file holding a block quote whose lines together are wider than 60 columns shows in a 60-column window
- **THEN** every row of the quote starts with its bar and no row is wider than 60 columns

#### Scenario: Two lines indented four spaces
- **WHEN** the reading view of a Markdown file holding two consecutive lines each indented four spaces shows in a 60-column window
- **THEN** each line keeps its own row, as code, and the two do not flow into one

#### Scenario: Two indented code lines in a quote
- **WHEN** the reading view of a Markdown file holding the quote lines `>     x = 1` and `>     y = 2` shows in a 60-column window
- **THEN** each line keeps its own row behind the quote's bar, indented as code, and the two do not flow into one

#### Scenario: A quote line mixing spaces and markers
- **WHEN** the reading view of a Markdown file holding the line ` >  >  b`, alone or after the quote line `> > a`, shows in a 60-column window
- **THEN** it reads `b` behind two bars, the same text whether it starts its own row or joins `a`'s row

### Requirement: A table ends where another block starts
The rows of a table SHALL end at a blank line, a line holding no `|`, or a line that opens another block (a heading, a block quote, a list item, or a fence) even when it holds a `|`; that line SHALL show as its own row after the table.

#### Scenario: A heading with a pipe right after a table
- **WHEN** the reading view of a Markdown file holding a table directly followed by a heading line holding a `|` shows
- **THEN** the table's bottom border is followed by the heading's text as its own row, not by another table row

### Requirement: The reading view draws headings in their style
In the reading view a heading SHALL read as its text without its markers, drawn in `@markup.heading`.

#### Scenario: A heading in the reading view
- **WHEN** the reading view of a Markdown file holding the line `## Title` shows
- **THEN** its row reads `Title`, drawn in `@markup.heading`

### Requirement: The reading view frames fenced code
In the reading view a fenced code block SHALL be drawn in a frame from the icon set, one framed row per code line, the frame as wide as the block's widest line and never wider than the measure, a longer line continued on the next framed row. The code's text SHALL be drawn in `@markup.raw.block`, under the tokens of the fence's language when a plugin tokenizes it.

#### Scenario: A framed code block
- **WHEN** the reading view of a Markdown file holding a fenced block of the lines `x = 1` and `yy = 22` shows in a 60-column window
- **THEN** the block reads as a top border, the rows `│ x = 1   │` and `│ yy = 22 │`, and a bottom border, each code line's text drawn in `@markup.raw.block`

#### Scenario: A code line wider than the measure
- **WHEN** the reading view of a Markdown file holding a fenced block with a line longer than the measure shows in a 20-column window
- **THEN** every row of the frame is 20 columns wide and the line continues on the next framed row

#### Scenario: A framed code block under ascii
- **WHEN** `option.icons ascii` is set and the reading view of a Markdown file holding a fenced block shows
- **THEN** the frame is drawn with `+`, `-`, and `|`, and no character above code point 127
