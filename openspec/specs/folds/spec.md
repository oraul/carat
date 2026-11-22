# folds Specification

## Purpose
Collapses lines of a window into manual folds, as Neovim's foldmethod=manual does: the fold keys create, open, close, and delete them, a closed fold is drawn as one row, and motions and operators treat it as one line.

## Requirements

### Requirement: zf creates a closed manual fold over the lines of a motion or a selection
`zf{motion}` in normal mode and `zf` in the visual modes SHALL create a fold of the current window over the lines the motion or the selection covers, closed, with the cursor on its first line. A fold inside an existing fold, sharing its first or last row included, SHALL nest in it, and a fold holding an existing fold SHALL hold it as nested; a fold crossing an existing fold, each holding rows the other does not, SHALL grow to contain it.

#### Scenario: zfj leaves a closed two-line fold drawn as one row
- **WHEN** "zfj" is typed on the first of the lines "one", "two", "three"
- **THEN** the window's first row shows "+--  2 lines: one" filled with "·", the second row shows "three", and the cursor is on row 0

#### Scenario: zf in linewise visual mode folds the selection
- **WHEN** "Vjjzf" is typed on the first of five lines
- **THEN** rows 0 to 2 are one closed fold and the mode is normal

#### Scenario: zf at the first row of an open fold nests in it
- **WHEN** "zf3jzozfj" is typed on the first of the lines "a", "b", "c", "d", "e"
- **THEN** the window has an open fold over rows 0 to 3 and a closed fold over rows 0 and 1 nested in it, and the first row shows "+---  2 lines: a" filled with "·"

### Requirement: The fold keys open, close, toggle, and delete folds
`zo` SHALL open the closed fold under the cursor, `zc` SHALL close the innermost open fold under the cursor, `za` SHALL open the fold under the cursor when it is closed and close it otherwise, `zd` SHALL delete the fold under the cursor, a closed one first, keeping the folds nested in it, and `zE` SHALL delete every fold of the window. `zo`, `zc`, `za`, and `zd` with no fold under the cursor SHALL give "E490: No fold found".

#### Scenario: zo opens a closed fold
- **WHEN** "zfjzo" is typed on the first of the lines "one", "two", "three"
- **THEN** the rows show "one", "two", "three"

#### Scenario: zc closes an open fold
- **WHEN** "zfjzojzc" is typed on the first of the lines "one", "two", "three"
- **THEN** the first row shows the fold text and the cursor is on row 0

#### Scenario: za toggles a fold
- **WHEN** "zfjza" is typed, then "za" again
- **THEN** the fold is open after the first "za" and closed after the second

#### Scenario: zd deletes the fold under the cursor
- **WHEN** "zfjzd" is typed on the first of the lines "one", "two", "three"
- **THEN** the window has no fold and the rows show "one", "two", "three"

#### Scenario: zE deletes every fold
- **WHEN** "zfjjjzfjzE" is typed on the first of five lines
- **THEN** the window has no fold

#### Scenario: A fold key with no fold gives E490
- **WHEN** "zo" is typed where there is no fold
- **THEN** the message is "E490: No fold found"

### Requirement: j and k pass a closed fold as one line
`j` and `k` SHALL count a closed fold as one line and land on its first line, and outside insert and replace modes a cursor any other command leaves inside a closed fold SHALL move to the fold's first line, where the fold is drawn, as Neovim's foldAdjustCursor does.

#### Scenario: j passes a closed fold
- **WHEN** "zfjj" is typed on the first of the lines "one", "two", "three"
- **THEN** the cursor is on row 2

#### Scenario: k lands on the first line of a closed fold
- **WHEN** "jzfjjk" is typed on the first of the lines "a", "b", "c", "d"
- **THEN** the cursor is on row 1

#### Scenario: A count G into a closed fold lands on its first line
- **WHEN** "jzfjgg3G" is typed on the first of the lines "one", "two", "three", "four"
- **THEN** the cursor is on row 1, drawn on the fold row

### Requirement: A linewise operator on a closed fold acts on all its lines
A linewise operator whose range starts or ends on a closed fold SHALL act on every line of that fold, a count counting the fold as one line. A fold whose lines are all deleted SHALL be gone, and the folds SHALL move with the lines edited above or inside them.

#### Scenario: dd on a closed fold deletes its lines
- **WHEN** "zfjdd" is typed on the first of the lines "one", "two", "three"
- **THEN** the lines are "three" and the window has no fold

#### Scenario: 2dd on a closed fold deletes the fold and the next line
- **WHEN** "zfj2dd" is typed on the first of the lines "a", "b", "c", "d"
- **THEN** the lines are "d"

#### Scenario: A fold moves down with a line put above it
- **WHEN** "jzfjggyyP" is typed on the lines "a", "b", "c", "d"
- **THEN** the fold covers rows 2 and 3

### Requirement: o and O on a closed fold open a line outside it
`o` on a closed fold SHALL open the new line below the fold's last line and `O` above its first line, as Neovim does, so the fold keeps its lines and the inserted text is shown.

#### Scenario: o on a closed fold opens a line below its last line
- **WHEN** "zfjoX<Esc>" is typed on the first of the lines "a", "b", "c"
- **THEN** the lines are "a", "b", "X", "c", the fold covers rows 0 and 1, closed, and the cursor is on row 2

#### Scenario: O on a closed fold opens a line above its first line
- **WHEN** "jjzfjOX<Esc>" is typed on the lines "a", "b", "c", "d", "e"
- **THEN** the lines are "a", "b", "X", "c", "d", "e", the fold covers rows 3 and 4, closed, and the cursor is on row 2

### Requirement: A failed plugin edit leaves the folds as before
A plugin edit request that fails after its edits began SHALL leave every window's folds over the buffer as they were before the request: the same rows, nesting, and open or closed state, a fold its edits shrank or dropped included.

#### Scenario: A reverted plugin edit leaves the folds as before
- **WHEN** a window has a closed fold over rows 1 to 2 and an open fold over rows 3 to 4, and a plugin edit request deletes rows 1 to 2 and inserts a line above row 3, then fails
- **THEN** the lines are as before and the window's folds are again a closed fold over rows 1 to 2 and an open fold over rows 3 to 4

### Requirement: Insert mode opens the closed folds under the cursor
Entering insert or replace mode SHALL open every closed fold holding the cursor, as Neovim's foldOpenCursor does when an insert session starts, so the edited line is shown.

#### Scenario: zfjiX opens the fold and edits its first line
- **WHEN** "zfjiX<Esc>" is typed on the lines "a", "b", "c", "d", "e"
- **THEN** the first line is "Xa" and the fold covers rows 0 and 1, open

### Requirement: zR and zM open and close every fold
`zR` SHALL open every fold of the window and `zM` SHALL close every fold of the window, the cursor going to the first line of the closed fold it is left in. Neither SHALL give a message when the window has no fold.

#### Scenario: zR opens every fold
- **WHEN** "zf3jzojzfjzR" is typed on the first of the lines "a" to "e"
- **THEN** the window has an open fold over rows 0 to 3 and an open fold over rows 1 and 2

#### Scenario: zM closes every fold
- **WHEN** "zf3jzojzfjzRzM" is typed on the first of the lines "a" to "e"
- **THEN** both folds are closed and the cursor is on row 0

#### Scenario: zR with no fold gives no message
- **WHEN** "zR" is typed where there is no fold
- **THEN** the message is empty

### Requirement: zj and zk move to the next and the previous fold
`zj` SHALL move the cursor to the first line of the next fold and `zk` to the last line of the previous fold, a closed fold counted as one fold and the deepest level that moves the cursor winning.

#### Scenario: zj moves to the start of the next fold
- **WHEN** "zj" is typed on row 0 above an open fold over rows 1 and 2
- **THEN** the cursor is on row 1, column 0

#### Scenario: zk moves to the end of the previous fold
- **WHEN** "zk" is typed on the last row below an open fold over rows 5 to 8
- **THEN** the cursor is on row 8

#### Scenario: zj counts a closed fold as one fold
- **WHEN** "3zj" is typed on row 0 after "zM" closed every fold
- **THEN** the cursor is on row 5, the first line of the closed outer fold, not on its nested fold

### Requirement: [z and ]z move to the edges of the open fold
`[z` SHALL move the cursor to the first line of the innermost open fold holding it and `]z` to its last line, or to the containing fold's when already there, stopping at a closed fold.

#### Scenario: [z moves to the start of the open fold
- **WHEN** "[z" is typed on row 7 inside an open fold over rows 6 and 7 nested in one over rows 5 to 8
- **THEN** the cursor is on row 6

#### Scenario: ]z moves to the end of the open fold
- **WHEN** "]z" is typed on row 6 inside an open fold over rows 6 and 7 nested in one over rows 5 to 8
- **THEN** the cursor is on row 7

### Requirement: The fold motions repeat by a count and are exclusive jumps
`zj`, `zk`, `[z`, and `]z` SHALL repeat count times, land in column 0, act as an exclusive charwise motion under an operator and in the visual modes, record a jump, and leave the cursor where no fold edge is beyond it.

#### Scenario: A fold motion with no fold beyond the cursor leaves it
- **WHEN** "[z" is typed on a row no fold holds
- **THEN** the cursor does not move

#### Scenario: dzj deletes up to the next fold
- **WHEN** "ldzj" is typed on row 0 above a fold starting on row 1
- **THEN** the characters from the cursor to the end of row 0 are deleted, as an exclusive motion ending in column 0 is

#### Scenario: zj is a jump
- **WHEN** "zj<C-o>" is typed on row 0
- **THEN** the cursor is back on row 0

### Requirement: A closed fold's row is drawn in Folded
The text of a closed fold's row, its fold text and its fill, SHALL be drawn in the `Folded` group, in every theme, at every color depth, under `option.icons ascii`, and under `NO_COLOR`; its gutter SHALL keep the line number and sign groups. On the cursor line the row SHALL take `Folded` over `CursorLine`'s background. The rows of open folds and of lines outside a fold SHALL keep their own groups.

#### Scenario: A closed fold's row is in Folded
- **WHEN** the first two of the lines "one", "two", "three" are one closed fold and the window is drawn
- **THEN** every text cell of the fold row is in `Folded` and the row of "three" is in `Normal`

#### Scenario: The fold row in both carat themes
- **WHEN** a closed fold is drawn under `carat-dark` and under `carat-light`
- **THEN** its text takes the palette's dim color at 24 bits and basic color 8 at 16 colors, unlike the `Normal` text beside it

#### Scenario: The fold row under ascii and NO_COLOR
- **WHEN** a closed fold is drawn with `option.icons ascii`, and again with `NO_COLOR` set
- **THEN** its text cells are in `Folded` both times

#### Scenario: The fold row on the cursor line
- **WHEN** the cursor is on a closed fold with `option.cursorline` on in the current window
- **THEN** its text cells are in `Folded` on the cursor-line layer
