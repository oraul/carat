## ADDED Requirements

### Requirement: Insert mode leaves the message row blank
In insert mode with no message pending the message row SHALL be blank, since the status bar's mode pill shows the mode; a message SHALL still show.

#### Scenario: No indicator in insert mode
- **WHEN** "i" is pressed
- **THEN** the message row is blank and the status bar shows the INSERT pill

## REMOVED Requirements

### Requirement: The mode indicator shows insert mode
**Reason**: The status bar's mode pill shows the mode, so the message row no longer repeats it.
**Migration**: "Insert mode leaves the message row blank" states the new rule; the pill is specified by the status-bar spec.
