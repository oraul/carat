# visual-mode Specification

## Purpose
Visual mode lets the user select text with the anchor and the cursor in three kinds, charwise, linewise, and blockwise, move the cursor end with every motion and text object, and keep the last selection of each window for reselecting.

## Requirements

### Requirement: v, V, and Ctrl-V start a visual mode
Pressing "v", "V", or "<C-v>" in normal mode SHALL enter charwise, linewise, or blockwise visual mode with the anchor and the cursor at the cursor position. A count typed before the key SHALL be ignored.

#### Scenario: v starts charwise visual mode
- **WHEN** "v" is pressed at (0, 1) of "abc"
- **THEN** the mode is visual and the selection is the character at (0, 1)

#### Scenario: V starts linewise visual mode
- **WHEN** "V" is pressed on row 1 of ["a", "b"]
- **THEN** the mode is visual_line and row 1 is selected

#### Scenario: Ctrl-V starts blockwise visual mode
- **WHEN** "<C-v>" is pressed at (0, 0)
- **THEN** the mode is visual_block

### Requirement: The same key leaves and another key switches the kind
In a visual mode, pressing the key of the same kind SHALL return to normal mode, and pressing the key of another kind SHALL switch to that kind keeping the anchor and the cursor.

#### Scenario: v twice
- **WHEN** "vlv" is pressed at (0, 0) of "abc"
- **THEN** the mode is normal and the cursor is at (0, 1)

#### Scenario: v then V
- **WHEN** "vjV" is pressed at (0, 1) of ["ab", "cd", "ef"]
- **THEN** the mode is visual_line with rows 0 and 1 selected

### Requirement: Escape and Ctrl-C leave visual mode
Escape and "<C-c>" in a visual mode SHALL return to normal mode without changing the buffer, and the cursor SHALL stay where it was, moved onto the last character when it rested on the end of the line.

#### Scenario: Escape after $
- **WHEN** "v$<Esc>" is pressed at (0, 0) of "abc"
- **THEN** the mode is normal, the cursor is at (0, 2), and the line is "abc"

#### Scenario: Ctrl-C leaves
- **WHEN** "Vj<C-c>" is pressed on row 0 of ["a", "b"]
- **THEN** the mode is normal and the cursor is on row 1

### Requirement: The selection runs between the anchor and the cursor
The charwise selection SHALL cover every character from the earlier of the anchor and the cursor to the later one, both included; the linewise selection every row between them; the blockwise selection the rows between them over the display columns from the leftmost to the rightmost of the two characters' cells.

#### Scenario: Charwise across lines
- **WHEN** "vjy" is pressed at (0, 1) of ["abc", "def"]
- **THEN** the unnamed register holds "bc\nde"

#### Scenario: Cursor before the anchor
- **WHEN** "vhhy" is pressed at (0, 2) of "abcd"
- **THEN** the unnamed register holds "abc"

#### Scenario: Block over two rows
- **WHEN** "<C-v>jly" is pressed at (0, 1) of ["abcd", "efgh"]
- **THEN** the register holds the block "bc\nfg"

### Requirement: Motions move the cursor end with counts
Every motion of the normal map SHALL be bound in the three visual maps and move the cursor end of the selection, with a count, while the anchor stays; the find motions read their character as in normal mode. The cursor MAY rest on the end of a line in visual mode, where "l", "$", and vertical motions to a shorter line put it.

#### Scenario: Count with a word motion
- **WHEN** "v2wy" is pressed at (0, 0) of "one two three"
- **THEN** the unnamed register holds "one two t"

#### Scenario: l reaches the end of the line
- **WHEN** "vlll" is pressed at (0, 0) of "ab"
- **THEN** the cursor is at (0, 2)

#### Scenario: Find in visual mode
- **WHEN** "vfcd" is pressed at (0, 0) of "abcd"
- **THEN** the line is "d"

### Requirement: The end of a line includes the line break
A charwise selection whose later end rests on the end of a line or on an empty line SHALL include that line's line break, unless it is the last line of the buffer.

#### Scenario: v$ joins the next line on delete
- **WHEN** "v$d" is pressed at (0, 1) of ["ab", "cd"]
- **THEN** the lines are ["acd"]

#### Scenario: An empty line is deleted
- **WHEN** "vd" is pressed on row 1 of ["a", "", "b"]
- **THEN** the lines are ["a", "b"]

### Requirement: o and O move to the other end
"o" SHALL exchange the anchor and the cursor. In blockwise visual mode "O" SHALL move the cursor to the other corner on the same row, moving the anchor to the opposite column on its own row; in the other kinds it SHALL act as "o".

#### Scenario: o swaps the ends
- **WHEN** "vllo" is pressed at (0, 0) of "abcd"
- **THEN** the cursor is at (0, 0) and the selection still covers "abc"

#### Scenario: O in a block
- **WHEN** "<C-v>jllO" is pressed at (0, 0) of ["abcd", "efgh"]
- **THEN** the cursor is at (1, 0) and the block still covers columns 0 to 2

### Requirement: gv reselects the last selection of the window
Leaving visual mode, by a key or by an operator, SHALL store the selection's kind, anchor, and cursor on the window. "gv" in normal mode SHALL restore it, clamped to the buffer; inside visual mode "gv" SHALL exchange the current selection with the stored one. "gv" with nothing stored SHALL do nothing, and a window shown another buffer SHALL forget its stored selection.

#### Scenario: gv after an escape
- **WHEN** "vl<Esc>0gvy" is pressed at (0, 1) of "abcd"
- **THEN** the unnamed register holds "bc"

#### Scenario: gv after a delete
- **WHEN** "Vd" then "gv" are pressed on row 0 of ["a", "b"]
- **THEN** the mode is visual_line on row 0

#### Scenario: gv with nothing stored
- **WHEN** "gv" is pressed in a fresh window
- **THEN** the mode is normal

### Requirement: Text objects select or extend the selection
A text object in visual mode SHALL select the count-th object when the selection is one character (one row for "ip" and "ap"). On a larger selection word, sentence, and paragraph objects SHALL move the cursor end over count more objects, and bracket and quote objects SHALL select the smallest object strictly larger than the selection, leaving it unchanged when there is none.

#### Scenario: viw selects the word
- **WHEN** "viwy" is pressed at (0, 5) of "one two three"
- **THEN** the unnamed register holds "two"

#### Scenario: iw again extends
- **WHEN** "viwiwiwy" is pressed at (0, 0) of "one two three"
- **THEN** the unnamed register holds "one two"

#### Scenario: i( twice selects the outer pair
- **WHEN** "vi(i(y" is pressed at (0, 3) of "(a(bc)d)"
- **THEN** the unnamed register holds "a(bc)d"

### Requirement: Text objects set the kind they produce
A charwise text object SHALL turn a linewise selection charwise, and a linewise text object ("ip", "ap", and an inner bracket object between brackets that end their lines) SHALL turn the selection linewise.

#### Scenario: vip becomes linewise
- **WHEN** "vip" is pressed on row 0 of ["a", "b", "", "c"]
- **THEN** the mode is visual_line with rows 0 and 1 selected

#### Scenario: Viw becomes charwise
- **WHEN** "Viw" is pressed at (0, 0) of "one two"
- **THEN** the mode is visual

### Requirement: Visual keys use the command grammar
In a visual mode a count and a "x register prefix SHALL be read as in normal mode, an operator key SHALL act on the selection at once instead of waiting for a motion, and a key no visual map binds SHALL drop the pending count and register and stay in visual mode.

#### Scenario: Register prefix
- **WHEN** "v\"ay" is pressed at (0, 0) of "ab"
- **THEN** register "a" holds "a"

#### Scenario: Unbound key
- **WHEN** "vQ" is pressed
- **THEN** the mode is still visual

### Requirement: The mode line names the visual mode
In a visual mode with no message showing, the message row SHALL begin with "-- VISUAL --", "-- VISUAL LINE --", or "-- VISUAL BLOCK --", and the keys of a pending count or register SHALL show at its right edge.

#### Scenario: Linewise indicator
- **WHEN** "V" is pressed
- **THEN** the message row begins with "-- VISUAL LINE --"

#### Scenario: Pending count
- **WHEN** "v2" is pressed
- **THEN** the message row ends with "2"
