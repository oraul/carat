# keymap-config Specification

## Purpose
Key bindings come only from JSON configuration: one map per mode from a key sequence in Vim notation to an action name or a key sequence to replay. The keymap decides, key by key, whether a sequence is complete, still a prefix, or unbound, and the editor waits a bounded time on an ambiguous prefix.

## Requirements

### Requirement: Bindings are loaded from the configuration per mode
The editor SHALL build its key bindings from the default bindings of every enabled plugin's manifest and then from the "keymaps" object of the configuration, one map per mode named there, so a configuration binding of the same keys replaces a plugin's, null removes it, and no binding comes from anywhere else. A key in Vim notation SHALL bind the sequence it denotes, with <leader> expanded from the configuration's "leader". An action name is namespace segments and the action, joined by dots.

#### Scenario: Default normal-mode binding
- **WHEN** the default configuration is loaded and the key "j" is pressed in normal mode
- **THEN** the action "cursor.down" is selected

#### Scenario: Leader binding
- **WHEN** the default configuration is loaded with leader " " and the keys Space then "w" are pressed in normal mode
- **THEN** the sequence ":w<CR>" is selected for replay

#### Scenario: Insert-mode binding
- **WHEN** the default configuration is loaded and Escape is pressed in insert mode
- **THEN** the action "mode.normal" is selected

#### Scenario: Plugin default binding
- **WHEN** the hello plugin is enabled and Space, "h", "h" are pressed in normal mode
- **THEN** the action "plugin.hello.greet" is selected

#### Scenario: Configuration wins over a plugin
- **WHEN** the configuration binds "<leader>hh" to "cursor.down" and the hello plugin is enabled
- **THEN** Space, "h", "h" select "cursor.down"

#### Scenario: Configuration unbinds a plugin key
- **WHEN** the configuration maps "<leader>hh" to null and the hello plugin is enabled
- **THEN** Space, "h", "h" are unbound

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

### Requirement: Unknown action names are reported when the configuration loads
When the configuration is loaded, a binding whose value is an action name that neither the editor nor a registered plugin declares SHALL be reported with the file name and the JSON path, as "config/default.json: keymaps.normal.zq: unknown action foo.bar", and SHALL not be added, while every other binding still loads. After startup the message row SHALL show the first report as an error, with the number of further reports.

#### Scenario: Unknown action in a binding
- **WHEN** the configuration binds "zq" in normal mode to "foo.bar" and the editor starts on "a.txt"
- **THEN** the message row shows "config/default.json: keymaps.normal.zq: unknown action foo.bar" as an error, and pressing "z", "q" does nothing

#### Scenario: Several unknown actions
- **WHEN** the configuration binds "zq" in normal mode to "foo.bar" and "zw" in insert mode to "foo.baz"
- **THEN** both are reported and the message row shows the first followed by " (and 1 more)"

#### Scenario: A plugin action is known
- **WHEN** the configuration binds "zh" in normal mode to "plugin.hello.greet" and the hello plugin is registered
- **THEN** nothing is reported and "z", "h" greets

#### Scenario: The default configuration is clean
- **WHEN** the editor starts with the default configuration
- **THEN** no configuration problem is reported
