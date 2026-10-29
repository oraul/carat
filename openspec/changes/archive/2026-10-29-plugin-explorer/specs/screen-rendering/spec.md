# Spec Delta

## MODIFIED Requirements

### Requirement: Message row content
The message row SHALL show, in priority order, the command line prefixed by ":" in command-line mode, or by a plugin's prompt text in place of ":" while a plugin prompt is open, the pending message if one was set by the last action, or "-- INSERT --" in insert mode, and SHALL be blank otherwise. A message SHALL stay until the next key is handled. The cursor SHALL be placed after the command line text.

#### Scenario: Message replaces the mode indicator
- **WHEN** ":q" is run on a modified buffer
- **THEN** the message row reads "E37: No write since last change (add ! to override)"

#### Scenario: Message clears on the next key
- **WHEN** a message is showing and "l" is pressed
- **THEN** the message row is blank

#### Scenario: Prompt in place of the colon
- **WHEN** a plugin prompts "Rename to: " with the initial value "a.rb"
- **THEN** the message row reads "Rename to: a.rb" and the cursor is in column 15 of it
