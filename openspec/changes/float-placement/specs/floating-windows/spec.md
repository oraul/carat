## MODIFIED Requirements

### Requirement: A float is placed by its spec over the layout
A float SHALL show its buffer in a box of the given text rows and columns, padded by one column on each side and bordered when asked, its top-left corner at the given offset from the editor's top-left cell ("editor") or the cursor cell ("cursor"). The box SHALL stay on the screen above the message row, less its margin when editor-anchored: its size cut first, then moved in. The windows under it SHALL keep their size and text.

#### Scenario: Editor-anchored float with a border and a title
- **WHEN** a float of 2 rows by 10 columns with a border and the title "doc" is opened at row 2, column 4 of the editor in a 40 by 12 editor
- **THEN** rows 2 to 5 from column 4 to 17 show a rounded border with "doc" centered on its top edge and the float's two lines inside it after one column of padding, and the rest of the rows show the window under it

#### Scenario: Cursor-anchored float
- **WHEN** a float without a border is opened at row 1, column 0 from the cursor while the cursor is on screen row 2, column 8
- **THEN** screen row 3 shows one column of padding at column 8 and the float's first line from column 9

#### Scenario: A float too large for the screen is cut and moved in
- **WHEN** a float of 30 rows by 100 columns is opened at row 5, column 50 in a 40 by 12 editor
- **THEN** its box spans rows 1 to 9 and columns 1 to 38, leaving the top row, the row above the message row, and the first and last columns to the windows under it

### Requirement: A float's text fits the screen beside its frame
A float's frame SHALL be its padding, one column on each side, and its border, one column on each side, when it is bordered and `option.winborder` draws an edge. The floats the editor opens (the palette, the documentation, signature, and definition floats, and the key hints) SHALL lay their rows out no wider than the screen less its margin and that frame, so placement cuts none of their rows.

#### Scenario: The palette keeps its right border while the filter shrinks
- **WHEN** the screen is 120 by 36 or 60 by 24 and "<Space>p" is typed and then a filter one key at a time until nothing matches
- **THEN** after each key every row of the palette's box ends with its right border in the box's last column, and each row is shown whole up to the padding before that border

#### Scenario: Without an edge the palette uses the border columns
- **WHEN** `option.winborder none` is set, the screen is 60 by 24, and "<Space>p" is typed
- **THEN** the palette's text is 56 columns wide, the screen less its margin and its padding, and each row is shown whole

#### Scenario: An 80-column hover row shows its last word
- **WHEN** the screen is 80 columns wide and `K` shows documentation of one paragraph longer than the screen
- **THEN** the float's rows are wrapped at 74 columns and the last word of each row is drawn inside the box, before its right padding and border

#### Scenario: The signature and the peek fit a narrow screen
- **WHEN** the screen is 40 columns wide and a signature label or a peeked definition line is longer than the screen
- **THEN** the float's text is 34 columns wide and shown whole inside its border

#### Scenario: The key hints use the border columns without an edge
- **WHEN** the screen is 38 by 8 and "<Space>x" shows nine hints of 10 cells, or a hint longer than the screen, once under `rounded` and once under `none`
- **THEN** the hints' text is at most 32 columns wide under `rounded`, fitting 2 columns of hints, and at most 34 under `none`, fitting 3, the long hint cut to that width, and every hint row laid out is shown

#### Scenario: The frame rule
- **WHEN** a float's widest text is asked for a 40-column screen under `rounded` and under `none`
- **THEN** it is 34 and 36 columns, and a placed box of that text fills the screen less its margin, never cut

## ADDED Requirements

### Requirement: A float keeps a margin from the screen's edges
An editor-anchored float's box SHALL keep one cell from each side of the screen above the message row, so it never covers the first or the last column, the top row, or the row above the message row. A cursor-anchored float SHALL follow its anchor cell to the screen's edge, so a popup's labels stay under the word. The box SHALL be cut to keep its margin, and only when the screen cannot hold a one-cell text area with its frame and margin on an axis SHALL the box use the margin cells of that axis.

#### Scenario: A float keeps its margin at the corner
- **WHEN** a bordered float of 1 row by 4 columns is placed at row 10, column 38 of the editor in a 40-column area of 11 rows
- **THEN** its box moves up and left to rows 7 to 9 and columns 31 to 38, one cell inside the area's last row and column

#### Scenario: A cursor float follows its anchor to the edge
- **WHEN** the same float is placed one row below a cursor cell at row 9, column 38
- **THEN** its box spans rows 8 to 10 and columns 32 to 39, the area's last row and column

#### Scenario: A screen too small for the margin
- **WHEN** a bordered float of 3 rows by 3 columns is placed in an area of 1 row by 2 columns
- **THEN** its box starts at the area's top-left cell with a one-cell text area

### Requirement: A centered float is placed at show and on resize
A float the editor opens centered SHALL have its column computed from its own box width each time the floats are placed, so its box is centered on the screen when it shows and again after the screen is resized, under every border style. The command palette SHALL be such a float.

#### Scenario: A centered box under both borders
- **WHEN** a centered bordered float 10 columns wide is placed in a 40-column area, once with an edge and once without
- **THEN** its box spans columns 13 to 26 with the edge and 14 to 25 without, as many columns left of the box as right of it

#### Scenario: The palette is centered without a border
- **WHEN** `option.winborder none` is set, the screen is 60 by 24, and "<Space>p" is typed
- **THEN** the palette's box has as many columns left of it as right of it

#### Scenario: The palette is centered again after a resize
- **WHEN** the palette is open on a 120 by 36 screen and the screen is resized to 100 by 30
- **THEN** the palette's box is centered on the 100-column screen

#### Scenario: The edge follows the last placement
- **WHEN** a bordered float is placed with an edge and then without one
- **THEN** its edge reads 1 and then 0, and its box is two columns narrower the second time
