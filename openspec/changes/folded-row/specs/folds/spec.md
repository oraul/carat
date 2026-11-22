## ADDED Requirements

### Requirement: A closed fold's row is drawn in Folded
The text of a closed fold's row, its fold text and its fill, SHALL be drawn in the `Folded` group, in every theme, at every color depth, under `option.icons ascii`, and under `NO_COLOR`; its gutter SHALL keep the line number and sign groups. On the cursor line the row SHALL take `Folded` over `CursorLine`'s background. The rows of open folds and of lines outside a fold SHALL keep their own groups.

#### Scenario: A closed fold's row is in Folded
- **WHEN** "zfj" is typed on the first of the lines "one", "two", "three" and the window is drawn
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
