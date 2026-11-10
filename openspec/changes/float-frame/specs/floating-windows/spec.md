## MODIFIED Requirements

### Requirement: A float is placed by its spec over the layout
A float SHALL show its buffer in a box of the given text rows and columns, padded by one column on each side and bordered when asked. Its top-left corner SHALL be the given offset from the editor's top-left cell (anchor "editor") or from the cursor cell of the window under it (anchor "cursor"). The box SHALL stay on the screen above the message row: its size cut to fit first, then its position moved in. The windows under it SHALL keep their size and their text.

#### Scenario: Editor-anchored float with a border and a title
- **WHEN** a float of 2 rows by 10 columns with a border and the title "doc" is opened at row 2, column 4 of the editor in a 40 by 12 editor
- **THEN** rows 2 to 5 from column 4 to 17 show a rounded border with "doc" centered on its top edge and the float's two lines inside it after one column of padding, and the rest of the rows show the window under it

#### Scenario: Cursor-anchored float
- **WHEN** a float without a border is opened at row 1, column 0 from the cursor while the cursor is on screen row 2, column 8
- **THEN** screen row 3 shows one column of padding at column 8 and the float's first line from column 9

#### Scenario: A float too large for the screen is cut and moved in
- **WHEN** a float of 30 rows by 100 columns is opened at row 5, column 50 in a 40 by 12 editor
- **THEN** its box fills the rows above the message row and the screen's columns

## ADDED Requirements

### Requirement: A float's padding takes the float's colors
The padding columns of a float SHALL be blank and drawn in the group of their row: `NormalFloat`, or for a menu `Pmenu`, and `PmenuSel` on its selected row, so a selected row spans the box from edge to edge.

#### Scenario: Padding in NormalFloat
- **WHEN** a bordered float is opened
- **THEN** the cell between its left border and its text and the cell between its text and its right border are blank in `NormalFloat`

#### Scenario: The selected row spans the padding
- **WHEN** the completion popup shows with its first row selected
- **THEN** the popup has no border, and the selected row's cells from the popup's first column to its last, the padding included, are in `PmenuSel`

### Requirement: The title is centered on the top edge
A float's title SHALL be drawn in `FloatTitle` centered between the corners of its top edge, with one blank cell on each side, and cut at a character boundary when the edge is too short for it.

#### Scenario: A centered title
- **WHEN** a bordered float 10 columns wide titled "doc" is opened
- **THEN** its top edge reads `╭─── doc ────╮` and the title's cells, its blanks included, are in `FloatTitle`

#### Scenario: A long title is cut
- **WHEN** a bordered float 4 columns wide is titled "a long title"
- **THEN** its top edge holds the corners, a blank on each side, and as much of the title as fits between them

### Requirement: The winborder option chooses the float border
`option.winborder` SHALL take Neovim's border styles: `rounded` (the default, `╭╮╰╯─│`), `single` (`┌┐└┘─│`), `double` (`╔╗╚╝═║`), `solid` (blank cells in `FloatBorder`), and `none` (bordered floats drawn with no edge and no title, their padding kept). Any other word SHALL be reported as `file:line: unknown border style WORD` and SHALL leave the value before it.

#### Scenario: The shipped border is rounded
- **WHEN** the editor starts with the shipped configuration
- **THEN** `winborder` is `rounded` and a bordered float has rounded corners

#### Scenario: Each border style
- **WHEN** `option.winborder` is `single`, `double`, or `solid` and a bordered float is opened
- **THEN** its corners and edges are drawn with that style's characters

#### Scenario: No border
- **WHEN** `option.winborder none` is set and a bordered float of 2 rows by 10 columns titled "doc" is opened at row 2, column 4
- **THEN** rows 2 and 3 from column 4 to 15 show the padding and the float's two lines, with no border and no title

#### Scenario: An unknown border style
- **WHEN** a configuration sets `option.winborder rounded` and then `option.winborder thick`
- **THEN** the second line is reported as `unknown border style thick` and `winborder` stays `rounded`

### Requirement: Borders have an ASCII form
Under `option.icons ascii`, or with `NO_COLOR` set, the border styles with lines SHALL be drawn with `+` corners, `-` edges, and `|` sides. Notification boxes SHALL be drawn with the same border as floats, blank under `none`.

#### Scenario: The ASCII border
- **WHEN** `option.icons ascii` is set and a bordered float titled "doc" 10 columns wide is opened
- **THEN** its top edge reads `+--- doc ----+`, its sides `|`, and its bottom edge `+` and `-`

#### Scenario: A notification follows the border style
- **WHEN** `option.winborder double` is set and a notification shows
- **THEN** its box is drawn with the double corners and edges
