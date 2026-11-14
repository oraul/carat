# floating-windows Specification

## Purpose
Floating windows show a buffer in a box drawn over a tab page's windows, placed relative to the editor or the cursor, stacked by z order, which the completion list and the documentation popups build on.

## Requirements

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

### Requirement: Floats stack by z order
A tab page SHALL hold at most 16 floats. A float with a higher z SHALL be drawn over one with a lower z, and of two floats with the same z the one opened later SHALL be drawn on top. Each tab page SHALL show only its own floats.

#### Scenario: Higher z on top
- **WHEN** a float of z 50 is opened, then an overlapping float of z 10
- **THEN** the overlapping cells show the float of z 50

#### Scenario: Floats belong to their tab page
- **WHEN** a float is open in the first tab page and the second tab page is shown
- **THEN** no float is drawn, and going back to the first tab page shows it again

### Requirement: Focus moves into and out of a float
A float opened with enter SHALL become the current window: keys move its cursor and scroll it, and the cursor is drawn in it. A Ctrl-W focus command in a float SHALL make the window that was current under it current again; focusing or splitting a window of the layout SHALL leave the float. `:q`, `:close`, and Ctrl-W c in a float SHALL close the float and make the window under it current, never closing a layout window or ending the editor.

#### Scenario: Moving in a focused float scrolls it
- **WHEN** a float of 3 rows showing 10 lines is focused and j is pressed four times
- **THEN** the float's cursor is on its fifth line, the float shows lines 4 to 6 (scrolloff capped at half its height), and the window under it has not moved

#### Scenario: Ctrl-W p leaves the float
- **WHEN** a float is focused and Ctrl-W p is pressed
- **THEN** the window under the float is current and the float stays open

#### Scenario: :q in a float closes only the float
- **WHEN** a float is focused in an editor with one window and :q is entered
- **THEN** the float is closed, the editor is running, and its window is current

### Requirement: Esc closes the topmost float
Esc in normal mode SHALL close the topmost float of the current tab page, focused or not, and do nothing when none is open.

#### Scenario: Esc closes the top one
- **WHEN** two floats are open and Esc is pressed in normal mode
- **THEN** the float drawn on top is closed and the other stays

#### Scenario: Esc with no float
- **WHEN** no float is open and Esc is pressed in normal mode
- **THEN** nothing changes and no message is shown

### Requirement: A float repaints only the rows it covers
Opening, scrolling, moving, or closing a float SHALL repaint no window row outside the rows the float covers or covered, and a window a float covers or covered SHALL be updated without a scroll region. With no float open, a key SHALL cost the same work as before floats existed.

#### Scenario: Closing a float rewrites only its rows
- **WHEN** a float covering rows 2 to 5 is closed
- **THEN** the frame after it has rows 2 to 5 dirty and no other text row of the window

#### Scenario: No scroll region under a float
- **WHEN** a float covers part of a full-width window and j scrolls that window by one line
- **THEN** the terminal receives no scroll region and the float is still drawn at its place

### Requirement: A float reopened at the same box shows its own text
A float closed and replaced by another float at the same box, both showing buffers with no edits, SHALL be drawn with the new float's text, so the screen equals a full repaint.

#### Scenario: Reopened at one box
- **WHEN** a float showing "one" is closed and a float showing "two" opens at the same box, after two redraws
- **THEN** the box shows "two" and the screen equals a full repaint

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

#### Scenario: The ASCII border under NO_COLOR
- **WHEN** `NO_COLOR` is set and a bordered float titled "doc" 10 columns wide is opened with the default `rounded` border
- **THEN** its top edge reads `+--- doc ----+`, its sides `|`, and its bottom edge `+` and `-`

#### Scenario: A notification follows the border style
- **WHEN** `option.winborder double` is set and a notification shows
- **THEN** its box is drawn with the double corners and edges

### Requirement: A float's text fits the screen beside its frame
A float's frame SHALL be its padding, one column on each side, and, when it is bordered and `option.winborder` draws an edge, its border, one column on each side. The floats the editor opens (the command palette, the documentation float, the signature float, the definition peek and pick list, and the key hints) SHALL lay their rows out no wider than the screen less that frame, so the screen cuts none of their rows and every row keeps its right padding and border at the box's edge.

#### Scenario: The palette keeps its right border while the filter shrinks
- **WHEN** the screen is 120 by 36 or 60 by 24 and "<Space>p" is typed and then a filter one key at a time until nothing matches
- **THEN** after each key every row of the palette's box ends with its right border in the box's last column, and each row is shown whole up to the padding before that border

#### Scenario: Without an edge the palette uses the border columns
- **WHEN** `option.winborder none` is set, the screen is 60 by 24, and "<Space>p" is typed
- **THEN** the palette's text is 58 columns wide, the screen less its padding, and each row is shown whole

#### Scenario: An 80-column hover row shows its last word
- **WHEN** the screen is 80 columns wide and `K` shows documentation of one paragraph longer than the screen
- **THEN** the float's rows are wrapped at 76 columns and the last word of each row is drawn inside the box, before its right padding and border

#### Scenario: The signature and the peek fit a narrow screen
- **WHEN** the screen is 40 columns wide and a signature label or a peeked definition line is longer than the screen
- **THEN** the float's text is 36 columns wide and shown whole, its right border in the screen's last column

#### Scenario: The key hints use the border columns without an edge
- **WHEN** the screen is 36 by 6 and "<Space>x" shows nine hints of 10 cells, or a hint longer than the screen, once under `rounded` and once under `none`
- **THEN** the hints' text is at most 32 columns wide under `rounded`, fitting 2 columns of hints, and at most 34 under `none`, fitting 3, the long hint cut to that width

#### Scenario: The frame rule
- **WHEN** a float's widest text is asked for a 40-column screen, bordered under `rounded`, bordered under `none`, and without a border
- **THEN** it is 36, 38, and 38 columns, and a placed box is never wider than the screen it is placed in
