# Spec Delta

## MODIFIED Requirements

### Requirement: Bindings are loaded from the configuration per mode
The editor SHALL build its key bindings from the default bindings of every enabled plugin's manifest and then from the "keymaps" object of the configuration, one map for each mode named there, so a configuration binding of the same keys replaces a plugin's, a configuration value of null removes it, and no binding comes from anywhere else. A key written in Vim notation SHALL bind the key sequence it denotes, with <leader> expanded from the configuration's "leader". An action name is one or more namespace segments followed by the action, each in lowercase letters, digits, and underscores, joined by dots.

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
