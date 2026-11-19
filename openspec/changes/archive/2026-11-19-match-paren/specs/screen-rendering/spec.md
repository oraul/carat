## ADDED Requirements

### Requirement: The bracket matching the cursor's is highlighted
When the cursor of the current window is on one of `(` `)` `[` `]` `{` `}` in normal, operator-pending, or a visual mode, that bracket and its partner SHALL be drawn in `MatchParen`, the partner searched only in the rows the window shows, nested brackets of the kind counted. Nothing SHALL be drawn for a bracket without a partner in view, in insert mode, in other windows, or in a window holding a closed fold, and the Visual selection SHALL win over the pair.

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

#### Scenario: A window with a closed fold draws no pair
- **WHEN** the cursor is on a bracket with its partner in view, in a window that holds a closed fold on another row
- **THEN** no cell is drawn in `MatchParen`
