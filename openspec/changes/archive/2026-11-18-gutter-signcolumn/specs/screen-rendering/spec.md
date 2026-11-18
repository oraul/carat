## MODIFIED Requirements

### Requirement: Signs take a column before the line numbers
A buffer with at least one sign SHALL be drawn with a sign column one cell wide at the left of its windows, before the line numbers, holding each sign's glyph on its row and a blank in `SignColumn` elsewhere, so the line numbers and the text start one cell after it; a buffer with no signs SHALL have no sign column.

#### Scenario: One sign
- **WHEN** the "error" sign of the ascii set is placed on row 1 of a three-line buffer with line numbers on
- **THEN** row 1 of the frame starts with "X  2 " and row 0 starts with "   1 "

#### Scenario: No signs
- **WHEN** the buffer has no signs
- **THEN** row 0 starts with "  1 "

#### Scenario: The sign column is one cell
- **WHEN** a sign is placed on row 1 of a three-line buffer with line numbers off
- **THEN** row 1 of the frame reads the glyph then the text at once, row 0 a blank cell in `SignColumn` then the text, and the cursor on row 0 is at column 1
