# Spec Delta

## MODIFIED Requirements

### Requirement: Bindings are loaded from the configuration per mode
The editor SHALL build its key bindings from the default bindings of every enabled plugin's manifest and then from the `keymap.<mode> <keys> <action>` lines of the configuration files in load order, the mode being one of normal, insert, visual, visual_line, visual_block, operator_pending, and cmdline, so a configuration binding of the same keys replaces a plugin's or an earlier line's, the action `none` removes the binding, and no binding comes from anywhere else. A key in Vim notation SHALL bind the sequence it denotes, with <leader> expanded from the last `keymap.leader` line, whose value is a key in Vim notation, or Vim's backslash when no line sets it. An action name is namespace segments and the action, joined by dots; any other value is a key sequence to replay.

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
