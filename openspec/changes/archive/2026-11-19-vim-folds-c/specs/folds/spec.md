## ADDED Requirements

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
