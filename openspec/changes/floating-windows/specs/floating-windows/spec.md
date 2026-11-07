## Purpose

Floating windows show a buffer in a box drawn over a tab page's windows, placed relative to the editor or the cursor, stacked by z order, which the completion list and the documentation popups build on.

## ADDED Requirements

### Requirement: A float is placed by its spec over the layout
A float SHALL show its buffer in a box of the given text rows and columns, with a one-cell border when asked and the title on the border's top edge. Its top-left corner SHALL be the given row and column offset from the editor's top-left cell (anchor "editor") or from the cursor cell of the window under it (anchor "cursor"). The box SHALL be kept on the screen above the message row: its size cut to fit first, then its position moved in. The windows under it SHALL keep their size and their text.

#### Scenario: Editor-anchored float with a border and a title
- **WHEN** a float of 2 rows by 10 columns with a border and the title "doc" is opened at row 2, column 4 of the editor in a 40 by 12 editor
- **THEN** rows 2 to 5 from column 4 to 15 show a rounded border with "doc" on its top edge and the float's two lines inside it, and the rest of the rows show the window under it

#### Scenario: Cursor-anchored float
- **WHEN** a float without a border is opened at row 1, column 0 from the cursor while the cursor is on screen row 3, column 5
- **THEN** the float's first line starts on screen row 4 at column 5

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
