# keymap-config Specification

## Purpose
Key bindings come only from JSON configuration: one map per mode from a key sequence in Vim notation to an action name or a key sequence to replay. The keymap decides, key by key, whether a sequence is complete, still a prefix, or unbound, and the editor waits a bounded time on an ambiguous prefix.

## Requirements

### Requirement: Bindings are loaded from the configuration per mode
The editor SHALL build its key bindings from the "keymaps" object of the configuration, one map for each mode named there, and from nothing else. A key written in Vim notation SHALL bind the key sequence it denotes, with <leader> expanded from the configuration's "leader".

#### Scenario: Default normal-mode binding
- **WHEN** the default configuration is loaded and the key "j" is pressed in normal mode
- **THEN** the action "cursor.down" is selected

#### Scenario: Leader binding
- **WHEN** the default configuration is loaded with leader " " and the keys Space then "w" are pressed in normal mode
- **THEN** the sequence ":w<CR>" is selected for replay

#### Scenario: Insert-mode binding
- **WHEN** the default configuration is loaded and Escape is pressed in insert mode
- **THEN** the action "mode.normal" is selected

### Requirement: A multi-key binding waits for the rest of its sequence
When the keys pressed so far are a proper prefix of a bound sequence and not themselves bound, the editor SHALL wait for the next key without dispatching anything.

#### Scenario: Prefix of gg
- **WHEN** "g" is pressed in normal mode with the default configuration
- **THEN** no action is dispatched and the editor is waiting for a second key

#### Scenario: Completing gg
- **WHEN** "g" then "g" are pressed in normal mode
- **THEN** the action "cursor.buffer_start" is dispatched once

### Requirement: An ambiguous prefix resolves after timeoutlen
When the keys pressed so far are bound and are also a prefix of a longer binding, the editor SHALL wait up to "timeoutlen" milliseconds for the next key; if none arrives in that time it SHALL dispatch the shorter binding.

#### Scenario: Shorter binding fires on timeout
- **WHEN** the configuration binds "a" to one action and "ab" to another, "a" is pressed, and timeoutlen passes
- **THEN** the action bound to "a" is dispatched

#### Scenario: Longer binding fires when completed in time
- **WHEN** the configuration binds "a" and "ab", and "a" then "b" are pressed within timeoutlen
- **THEN** only the action bound to "ab" is dispatched

### Requirement: An unbound sequence is dropped
When the keys pressed so far match no binding and are a prefix of none, the editor SHALL discard them; in insert mode and command-line mode the printable keys among them SHALL be inserted as text instead.

#### Scenario: Unbound key in normal mode
- **WHEN** "z" is pressed in normal mode with the default configuration
- **THEN** nothing is dispatched and the buffer and cursor are unchanged

#### Scenario: Printable key in insert mode
- **WHEN** "z" is pressed in insert mode
- **THEN** "z" is inserted at the cursor

### Requirement: A binding may replay a key sequence
A binding whose value is a key sequence in Vim notation rather than an action name SHALL replay those keys through the keymap of the current mode as if typed. Replay SHALL stop after 100 nested replays so a self-referencing binding cannot loop forever.

#### Scenario: Leader w writes the file
- **WHEN** Space then "w" are pressed in normal mode on a buffer with a path
- **THEN** the file is written exactly as if ":w" and Enter had been typed

### Requirement: Malformed bindings are reported and skipped
A binding whose key notation cannot be parsed SHALL be reported with its mode and key, and the rest of the configuration SHALL still load.

#### Scenario: One bad key among good ones
- **WHEN** a configuration binds "<Nope>" and "j" in normal mode
- **THEN** loading reports an error naming normal and "<Nope>", and "j" is bound
