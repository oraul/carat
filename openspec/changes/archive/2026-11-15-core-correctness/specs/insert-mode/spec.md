# Spec Delta

## ADDED Requirements

### Requirement: Expandtab pads to the tab stop by display column
With expandtab on, Tab SHALL insert the spaces that reach the next multiple of tabstop counted in screen cells, a tab before the cursor counting the cells it spans and a wide character two.

#### Scenario: Expandtab after a tab
- **WHEN** the line is a tab then "x" with tabstop 4 and expandtab on, and "A" then Tab are pressed
- **THEN** the line is a tab, "x", and three spaces, ending at screen cell 8, and the cursor is at column 5

#### Scenario: Expandtab after a wide character
- **WHEN** the line is the wide character "あ" with tabstop 4 and expandtab on, and "A" then Tab are pressed
- **THEN** the line is "あ" and two spaces, ending at screen cell 4, and the cursor is at column 3
