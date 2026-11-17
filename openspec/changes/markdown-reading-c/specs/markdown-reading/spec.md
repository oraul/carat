## ADDED Requirements

### Requirement: The reading view flows paragraphs and quotes to the measure
The lines of a paragraph SHALL show in the reading view as one text wrapped at the window's measure, and the lines of a block quote at one depth and indentation as one quote text wrapped at the measure, each row after the first keeping the quote's bars. A heading, a thematic break, a list item, fenced code, a table, a blank line, or a line ending in two spaces SHALL end the flowing text, and lines of different quote depths SHALL not flow together.

#### Scenario: A two-line paragraph at 60 columns
- **WHEN** the reading view of a Markdown file holding a paragraph written on two short lines shows in a 60-column window
- **THEN** the paragraph reads as one row holding both lines' words parted by one space

#### Scenario: A two-line quote at 60 columns
- **WHEN** the reading view of a Markdown file holding a block quote written on two short `>` lines shows in a 60-column window
- **THEN** the quote reads as one row behind one bar holding both lines' words parted by one space

#### Scenario: A flowed quote wider than the measure
- **WHEN** the reading view of a Markdown file holding a block quote whose lines together are wider than 60 columns shows in a 60-column window
- **THEN** every row of the quote starts with its bar and no row is wider than 60 columns

### Requirement: A table ends where another block starts
The rows of a table SHALL end at a blank line, a line holding no `|`, or a line that opens another block (a heading, a block quote, a list item, or a fence) even when it holds a `|`; that line SHALL show as its own row after the table.

#### Scenario: A heading with a pipe right after a table
- **WHEN** the reading view of a Markdown file holding a table directly followed by a heading line holding a `|` shows
- **THEN** the table's bottom border is followed by the heading's text as its own row, not by another table row
