## MODIFIED Requirements

### Requirement: Notifications

A notification SHALL be a bordered box of three rows at the top right, from the row under the buffer tabs, its right edge one column from the screen's, its text plus four wide within half the screen and at least 20. Its top border SHALL name its severity (`Error`, `Warning`, or `Info`) in that severity's group, centered with a blank on each side as a float title, its text in `NormalFloat`. A box reaching the status bar SHALL NOT be drawn; no box changes a buffer, cursor, or mode.

#### Scenario: A warning shows at the top right

- **WHEN** a warning notification `disk almost full` arrives on a 60-column screen
- **THEN** rows 0 to 2 end one column before the right edge with a box whose top border holds `Warning` and whose middle row holds `disk almost full`

#### Scenario: A notification title is centered like a float title

- **WHEN** `option.winborder double` is set and a warning notification `disk almost full` arrives on a 60-column screen
- **THEN** its top border reads `╔════ Warning ═════╗`, the title and its blanks in the warning's group
