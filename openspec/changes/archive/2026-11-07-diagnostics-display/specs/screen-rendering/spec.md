## MODIFIED Requirements

### Requirement: Message row content
The message row SHALL show, in priority order: the command line after ":" in command-line mode, or after a plugin's prompt text while one is open; the pending message set by the last action; the mode indicator "-- INSERT --", "-- VISUAL --", "-- VISUAL LINE --", or "-- VISUAL BLOCK --"; in normal mode the message of the most severe diagnostic on the cursor's line; else blank. A message SHALL stay until the next key is handled. The cursor SHALL be placed after the command line text.

#### Scenario: Message replaces the mode indicator
- **WHEN** ":q" is run on a modified buffer
- **THEN** the message row reads "E37: No write since last change (add ! to override)"

#### Scenario: Message clears on the next key
- **WHEN** a message is showing and "l" is pressed
- **THEN** the message row is blank

#### Scenario: Prompt in place of the colon
- **WHEN** a plugin prompts "Rename to: " with the initial value "a.rb"
- **THEN** the message row reads "Rename to: a.rb" and the cursor is in column 15 of it

#### Scenario: Visual block indicator
- **WHEN** "<C-v>" is pressed in normal mode
- **THEN** the message row reads "-- VISUAL BLOCK --"

#### Scenario: The cursor line's diagnostic
- **WHEN** the cursor is in normal mode on a line with a warning "unused" and no message is pending
- **THEN** the message row reads "unused" in the `DiagnosticWarn` group

#### Scenario: A pending message wins over the diagnostic
- **WHEN** the cursor is on a line with a diagnostic and the last action set a message
- **THEN** the message row shows the message
