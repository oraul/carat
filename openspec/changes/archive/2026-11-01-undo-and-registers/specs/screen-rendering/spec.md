# Spec Delta

## ADDED Requirements

### Requirement: A message of several lines takes the bottom rows
A message of several lines SHALL be drawn over the rows above the message row, its last lines when it is taller than the screen, with "Press ENTER or type command to continue" in the message row and the cursor after it. Enter or Space SHALL dismiss it; any other key SHALL dismiss it and be handled as usual.

#### Scenario: The registers listing
- **WHEN** ":registers" is run after "yy" on ["one"] in a 10-row screen
- **THEN** rows 5 to 8 show the four lines of the listing, row 9 reads "Press ENTER or type command to continue", and the windows are drawn above them

#### Scenario: Enter dismisses
- **WHEN** the listing shows and Enter is pressed
- **THEN** the windows are drawn again, the message row is blank, and the cursor has not moved

#### Scenario: Another key is handled
- **WHEN** the listing shows and "x" is pressed
- **THEN** the listing is gone and the character under the cursor is deleted
