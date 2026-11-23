## ADDED Requirements

### Requirement: A plugin marks a row of its scratch buffer as the current entry
A plugin SHALL be able to ask the host to draw one row of its own scratch buffer as the current entry (API 2.17, `mark_scratch_row`): its cells across the window in the selection fill, the first in the bar's group. A failed request SHALL change nothing, and replacing the buffer's lines SHALL clear the mark.

#### Scenario: A plugin marks a row
- **WHEN** a plugin marks row 1 of its scratch buffer "list"
- **THEN** the request succeeds and the buffer's marked row is 1

#### Scenario: A row outside the buffer
- **WHEN** a plugin marks row 9 of a buffer of five lines, or a row of a title it has no buffer for
- **THEN** the request fails with "Row 9 is outside the buffer" or "No scratch buffer nope" and the marked row is unchanged

#### Scenario: Clearing the mark
- **WHEN** a plugin marks row -1, or replaces the lines of a marked buffer
- **THEN** the buffer has no marked row

#### Scenario: Under NO_COLOR
- **WHEN** a row is marked and `NO_COLOR` is set
- **THEN** only the bar cell of the row is drawn in the bar's group
