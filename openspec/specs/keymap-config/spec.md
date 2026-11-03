# keymap-config Specification

## Purpose
Key bindings come only from JSON configuration: one map per mode from a key sequence in Vim notation to an action name or a key sequence to replay. The keymap decides, key by key, whether a sequence is complete, still a prefix, or unbound, and the editor waits a bounded time on an ambiguous prefix.

## Requirements

### Requirement: Bindings are loaded from the configuration per mode
Key bindings SHALL come from every enabled plugin's manifest defaults and then from the `keymap.<mode> <keys> <action>` lines of the configuration files in load order, so a later binding of the same keys replaces an earlier one, `none` removes it, and no binding comes from anywhere else. Keys in Vim notation SHALL bind what they denote, <leader> being the last `keymap.leader` value or a backslash. An action name is dotted segments; any other value is keys to replay.

#### Scenario: Default normal-mode binding
- **WHEN** the default configuration is loaded and the key "j" is pressed in normal mode
- **THEN** the action "cursor.down" is selected

#### Scenario: Leader binding
- **WHEN** the default configuration is loaded, which sets "keymap.leader <Space>", and the keys Space then "w" are pressed in normal mode
- **THEN** the sequence ":w<CR>" is selected for replay

#### Scenario: Insert-mode binding
- **WHEN** the default configuration is loaded and Escape is pressed in insert mode
- **THEN** the action "mode.normal" is selected

#### Scenario: Plugin default binding
- **WHEN** the hello plugin is enabled and Space, "h", "h" are pressed in normal mode
- **THEN** the action "plugin.hello.greet" is selected

#### Scenario: Configuration wins over a plugin
- **WHEN** a configuration line is "keymap.normal <leader>hh cursor.down" and the hello plugin is enabled
- **THEN** Space, "h", "h" select "cursor.down"

#### Scenario: Configuration unbinds a plugin key
- **WHEN** a configuration line is "keymap.normal <leader>hh none" and the hello plugin is enabled
- **THEN** Space, "h", "h" are unbound

#### Scenario: A later line rebinds
- **WHEN** the user file binds "Q" in normal mode to "cursor.down" and the project file binds it to "none"
- **THEN** "Q" is unbound

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
- **WHEN** "Q" is pressed in normal mode with the default configuration
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
A keymap line that names an unknown mode, does not have exactly keys and an action, or whose key notation cannot be parsed SHALL be reported as `file:line: message` and skipped, and the rest of the configuration SHALL still load.

#### Scenario: One bad key among good ones
- **WHEN** the project file's first line binds "<Nope>" in normal mode and its second line binds "j"
- **THEN** ".caratrc:1: unknown key <Nope>" is reported and "j" is bound

#### Scenario: Unknown mode
- **WHEN** the project file's first line is "keymap.command x cursor.down"
- **THEN** ".caratrc:1: unknown mode command" is reported

#### Scenario: Missing action
- **WHEN** the project file's first line is "keymap.normal x"
- **THEN** ".caratrc:1: keymap.normal takes keys and an action" is reported

### Requirement: Unknown action names are reported when the configuration loads
When the configuration is loaded, a binding whose value is an action name that neither the editor nor a registered plugin declares SHALL be reported as `file:line: unknown action NAME` and SHALL not be added, while every other binding still loads. After startup the message row SHALL show the first report as an error, with the number of further reports.

#### Scenario: Unknown action in a binding
- **WHEN** the project file's first line is "keymap.normal zq foo.bar" and the editor starts on "a.txt"
- **THEN** the message row shows ".caratrc:1: unknown action foo.bar" as an error, and pressing "z", "q" does nothing

#### Scenario: Several unknown actions
- **WHEN** the project file binds "zq" in normal mode to "foo.bar" on line 1 and "zw" in insert mode to "foo.baz" on line 2
- **THEN** both are reported and the message row shows ".caratrc:1: unknown action foo.bar (and 1 more)"

#### Scenario: A plugin action is known
- **WHEN** a configuration line binds "zh" in normal mode to "plugin.hello.greet" and the hello plugin is registered
- **THEN** nothing is reported and "z", "h" greets

#### Scenario: The default configuration is clean
- **WHEN** the editor starts with the default configuration
- **THEN** no configuration problem is reported

### Requirement: A keymap value with an illegal byte never stops the editor
Deciding whether a keymap value names an action SHALL read its bytes and SHALL never fail, whatever bytes the value holds, when the configuration loads, when a plugin's bindings are checked, and when a bound key is pressed. A value holding a byte outside a well-formed UTF-8 sequence is not an action name.

#### Scenario: Illegal byte in a trusted binding
- **WHEN** the user file binds "x" in normal mode to "a" followed by the byte FF and ".b", and the editor starts on "a.txt"
- **THEN** the editor starts, the message row shows "~/.config/carat/caratrc:1: illegal byte" as an error, and the rest of the configuration loads

#### Scenario: Illegal byte asked of the action check
- **WHEN** the value "plugin." followed by the byte FF is checked as an action name
- **THEN** it is not an action name and nothing is raised
