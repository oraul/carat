# Spec Delta

## MODIFIED Requirements

### Requirement: A multi-key binding waits for the rest of its sequence
When the keys pressed so far are a proper prefix of a bound sequence and not themselves bound, the editor SHALL wait for the next key without dispatching anything. In normal, operator-pending, and the visual modes the wait SHALL have no time limit, as Neovim's built-in commands have none; in insert and command-line modes the keys SHALL be resolved after "timeoutlen" as an unbound sequence.

#### Scenario: Prefix of gg
- **WHEN** "g" is pressed in normal mode with the default configuration
- **THEN** no action is dispatched and the editor is waiting for a second key

#### Scenario: Completing gg
- **WHEN** "g" then "g" are pressed in normal mode
- **THEN** the action "cursor.buffer_start" is dispatched once

#### Scenario: The wait outlasts timeoutlen
- **WHEN** "g" is pressed in normal mode on the last line, more than timeoutlen passes, and "g" is pressed
- **THEN** the cursor goes to the first line

#### Scenario: A key that continues nothing drops the prefix
- **WHEN** "g" is pressed in normal mode, more than timeoutlen passes, and Escape is pressed
- **THEN** nothing is pending and the buffer and cursor are unchanged

#### Scenario: Insert mode resolves after timeoutlen
- **WHEN** the configuration binds "jk" in insert mode, "j" is pressed in insert mode, and timeoutlen passes
- **THEN** "j" is inserted at the cursor

### Requirement: An unbound sequence is dropped
When the keys pressed so far match no binding and are a prefix of none, the editor SHALL discard them; in insert mode and command-line mode the printable keys among them SHALL be inserted as text instead.

#### Scenario: Unbound key in normal mode
- **WHEN** "Q" is pressed in normal mode with the default configuration
- **THEN** nothing is dispatched and the buffer and cursor are unchanged

#### Scenario: Printable key in insert mode
- **WHEN** "z" is pressed in insert mode
- **THEN** "z" is inserted at the cursor
