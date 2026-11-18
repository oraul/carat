## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: A failed plugin edit leaves the folds as before
A plugin edit request that fails after its edits began SHALL leave every window's folds over the buffer as they were before the request: the same rows, nesting, and open or closed state, a fold its edits shrank or dropped included.

#### Scenario: A reverted plugin edit leaves the folds as before
- **WHEN** a window has a closed fold over rows 1 to 2 and an open fold over rows 3 to 4, and a plugin edit request deletes rows 1 to 2 and inserts a line above row 3, then fails
- **THEN** the lines are as before and the window's folds are again a closed fold over rows 1 to 2 and an open fold over rows 3 to 4
