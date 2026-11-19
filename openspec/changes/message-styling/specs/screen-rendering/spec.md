## MODIFIED Requirements

### Requirement: Message row content
The message row SHALL show, in priority order: the command line after ":" in command-line mode, or after a plugin's prompt while one is open; the hit-enter line while a several-line message waits; the pending message set by the last action; the visual mode indicator; in normal mode the cursor line's most severe diagnostic; else blank. Insert mode shows no indicator. A message SHALL stay until the next key is handled. The cursor SHALL be placed after the command line text.

#### Scenario: Message replaces the mode indicator
- **WHEN** ":q" is run on a modified buffer
- **THEN** the message row reads "✖ E37: No write since last change (add ! to override)", the icon in `DiagnosticError`, the code in `ErrorMsg`, and the rest in `Normal`

#### Scenario: An error without a code
- **WHEN** an error message "no such name" is shown
- **THEN** the message row reads "✖ no such name", the icon in `DiagnosticError` and the text in `Normal`

#### Scenario: The error icon follows option.icons
- **WHEN** an error message is shown with `option.icons ascii`
- **THEN** the message row starts with "X "

#### Scenario: An information message is dim
- **WHEN** a message that is not an error is shown
- **THEN** the message row reads the message in `MsgDim`

#### Scenario: The command line's prompt is dim
- **WHEN** ":wq" is typed in command-line mode, or a plugin prompts "Rename to: " with the initial value "a.rb"
- **THEN** the prompt is drawn in `MsgDim` and the typed text in `Normal`

#### Scenario: Pending keys are dim
- **WHEN** the quote key, "a", "2", "d" are pressed
- **THEN** the message row ends with them in `MsgDim`

#### Scenario: The hit-enter line is a question
- **WHEN** a message of several lines is shown
- **THEN** the hit-enter line in the message row is drawn in `Question`

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

#### Scenario: NO_COLOR keeps the groups
- **WHEN** the frame presenter is plain, as `NO_COLOR` asks, and an error message is shown
- **THEN** the cells carry the same groups as without it
