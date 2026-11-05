# Spec Delta

## MODIFIED Requirements

### Requirement: Bindings are loaded from the configuration per mode
Key bindings SHALL come from every enabled plugin's manifest defaults and then from the `keymap.<mode> <keys> <action>` lines of the configuration files in load order, so a later binding of the same keys replaces an earlier one, `none` removes it, and no binding comes from anywhere else. Keys in Vim notation SHALL bind what they denote, <leader> being the last `keymap.leader` value or a backslash. An action name is dotted segments; any other value is keys to replay.

#### Scenario: Default normal-mode binding
- **WHEN** the default configuration is loaded and the key "j" is pressed in normal mode
- **THEN** the action "cursor.down" is selected

#### Scenario: Leader binding
- **WHEN** the default configuration is loaded, which sets "keymap.leader <Space>", and the keys Space, "w", "s" are pressed in normal mode
- **THEN** the action "window.split" is selected, and Space then "w" alone is a prefix

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

### Requirement: A binding may replay a key sequence
A binding whose value is a key sequence in Vim notation rather than an action name SHALL replay those keys through the keymap of the current mode as if typed. Replay SHALL stop after 100 nested replays so a self-referencing binding cannot loop forever.

#### Scenario: Leader w writes the file
- **WHEN** the user file holds "keymap.normal <leader>w :w<CR>", as the old default did, and Space then "w" are pressed in normal mode on a buffer with a path
- **THEN** the file is written exactly as if ":w" and Enter had been typed

## ADDED Requirements

### Requirement: Every core action carries a short description
Every action the editor's core registers SHALL carry a description of 1 to 32 characters saying what it does, for the key hints to show beside its keys; an action name no core handler registers SHALL have the empty description, a plugin's actions keeping the descriptions of their manifest.

#### Scenario: A window action is described
- **WHEN** the editor starts with the default configuration
- **THEN** "window.split" is described as "Split window" and "file.save" as "Save file"

#### Scenario: Every core action is described
- **WHEN** the editor starts with the default configuration
- **THEN** every registered core action has a description of 1 to 32 characters, and an unregistered name has the empty description
