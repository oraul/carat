## MODIFIED Requirements

### Requirement: The reading toggle shows a Markdown buffer as reading text
In normal mode `<leader>dr` (`docs.toggle_reading`) SHALL, in a window showing a buffer whose path ends in `.md` or `.markdown`, show in that window a scratch buffer titled `[reading] PATH` holding the file laid out as the documentation float lays out markdown, in the same styles, its fenced code framed, every row at most the window's width and at most 80 columns. A buffer that is not Markdown SHALL be refused with the message `Not a Markdown buffer` and nothing else changes.

#### Scenario: Toggling a Markdown buffer into the reading view
- **WHEN** a window shows `notes.md` holding a heading, a paragraph, a list, a quote, and a fenced block, and `<leader>dr` is typed
- **THEN** the window shows `[reading] notes.md` with the heading's text, the paragraph without markers, bullet rows, bar rows, and the code inside a frame, no row wider than 80 columns

#### Scenario: A buffer that is not Markdown
- **WHEN** a window shows `main.rb` and `<leader>dr` is typed
- **THEN** the message reads `Not a Markdown buffer` and the window still shows `main.rb`

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

## ADDED Requirements

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
