## Purpose

Collapses lines of a window into manual folds, as Neovim's foldmethod=manual does: the fold keys create, open, close, and delete them, a closed fold is drawn as one row, and motions and operators treat it as one line.

## ADDED Requirements

### Requirement: zf creates a closed manual fold over the lines of a motion or a selection
`zf{motion}` in normal mode and `zf` in the visual modes SHALL create a fold of the current window over the lines the motion or the selection covers, closed, with the cursor on its first line. A fold inside an existing fold SHALL nest in it; a fold crossing an existing fold SHALL grow to contain it.

#### Scenario: zfj leaves a closed two-line fold drawn as one row
- **WHEN** "zfj" is typed on the first of the lines "one", "two", "three"
- **THEN** the window's first row shows "+--  2 lines: one" filled with "·", the second row shows "three", and the cursor is on row 0

#### Scenario: zf in linewise visual mode folds the selection
- **WHEN** "Vjjzf" is typed on the first of five lines
- **THEN** rows 0 to 2 are one closed fold and the mode is normal

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
