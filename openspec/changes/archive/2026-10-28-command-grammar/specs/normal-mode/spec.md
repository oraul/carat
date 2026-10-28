# Spec Delta

## ADDED Requirements

### Requirement: Actions of later roadmap items report themselves
Pressing a key bound in the default configuration to an action no roadmap item has implemented yet SHALL show the message "Not implemented: " followed by the action name, and change nothing else.

#### Scenario: u before undo exists
- **WHEN** "u" is pressed in normal mode
- **THEN** the message is "Not implemented: history.undo" and the buffer is unchanged

## REMOVED Requirements

### Requirement: Actions from later roadmap items report themselves
**Reason**: Its only scenario used "dd", which the command grammar now implements as a linewise delete, so the scenario no longer describes the editor.
**Migration**: The behavior continues under the requirement "Actions of later roadmap items report themselves", whose scenario uses "u" until the undo change lands.
