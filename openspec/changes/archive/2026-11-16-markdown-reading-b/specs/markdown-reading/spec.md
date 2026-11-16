## ADDED Requirements

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

## MODIFIED Requirements

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
