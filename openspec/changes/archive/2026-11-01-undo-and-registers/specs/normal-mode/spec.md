# Spec Delta

## REMOVED Requirements

### Requirement: Actions of later roadmap items report themselves
**Reason**: Its only scenario pressed "u", which this change implements; the behavior continues under the requirement "Unimplemented actions report themselves" with an action still unimplemented.
**Migration**: None; the message for an unimplemented action is unchanged.

## ADDED Requirements

### Requirement: Unimplemented actions report themselves
Pressing a key bound in the default configuration to an action no roadmap item has implemented yet SHALL show the message "Not implemented: " followed by the action name, and change nothing else.

#### Scenario: / before search exists
- **WHEN** "/" is pressed in normal mode
- **THEN** the message is "Not implemented: search.forward" and the buffer is unchanged

### Requirement: r replaces characters
Pressing "r" and a character SHALL replace count characters from the cursor with that character, leaving the cursor on the last replaced one; when fewer than count characters remain on the line nothing SHALL change.

#### Scenario: Replace one
- **WHEN** "rx" is pressed at (0, 1) of ["abc"]
- **THEN** the line is "axc" and the cursor is at (0, 1)

#### Scenario: Replace with a count
- **WHEN** "3rx" is pressed at (0, 0) of ["abcd"]
- **THEN** the line is "xxxd" and the cursor is at (0, 2)

#### Scenario: Too few characters
- **WHEN** "5rx" is pressed at (0, 0) of ["abc"]
- **THEN** the line is "abc"

### Requirement: Tilde switches the case of characters
Pressing "~" SHALL switch the case of count characters from the cursor, as many as remain on the line, and move the cursor past them, stopping on the last character.

#### Scenario: Toggle and move
- **WHEN** "~" is pressed at (0, 0) of ["abC"]
- **THEN** the line is "AbC" and the cursor is at (0, 1)

#### Scenario: A count past the end
- **WHEN** "5~" is pressed at (0, 1) of ["abC"]
- **THEN** the line is "aBc" and the cursor is at (0, 2)
