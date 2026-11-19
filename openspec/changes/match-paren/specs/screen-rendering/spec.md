## ADDED Requirements

### Requirement: The bracket matching the cursor's is highlighted
When the cursor of the current window is on one of `(` `)` `[` `]` `{` `}` in normal, operator-pending, or a visual mode, that bracket and its partner SHALL be drawn in `MatchParen`. The partner SHALL be searched only in the rows the window shows, counting nested brackets of the kind. A bracket without a partner in view SHALL draw nothing, and so SHALL insert mode and the other windows.

#### Scenario: Both brackets of a pair are drawn
- **WHEN** the cursor is on the opening or the closing bracket of a pair of parentheses, square brackets, or braces, on one row or across rows, nested or not
- **THEN** both brackets are drawn in `MatchParen` and no other cell is

#### Scenario: An unmatched or off-screen pair is not drawn
- **WHEN** the cursor is on a bracket with no partner, or whose partner is not in a row the window shows
- **THEN** no cell is drawn in `MatchParen`

#### Scenario: Only the grammar's modes draw it
- **WHEN** the cursor is on a bracket in insert mode
- **THEN** no cell is drawn in `MatchParen`

#### Scenario: The row repaints when the cursor moves
- **WHEN** the cursor moves onto a bracket, and then off it
- **THEN** its row is drawn again each time, with the bracket in `MatchParen` and then without
