# Spec Delta

## MODIFIED Requirements

### Requirement: The explorer is a built-in plugin enabled by default
The `explorer` plugin SHALL be compiled into the editor and enabled by the shipped configuration with the lines `plugin.explorer.enabled true`, `plugin.explorer.width 30`, `plugin.explorer.side left`, `plugin.explorer.show_hidden false`, and `plugin.explorer.ignore .git build tmp`. Its default binding SHALL be `<leader>e` in normal mode for `plugin.explorer.toggle`, given by the plugin, so a user binding of the same keys replaces it.

#### Scenario: Enabled with its options
- **WHEN** the editor starts with the shipped configuration
- **THEN** the explorer plugin is enabled and its `width` option reads "30"

#### Scenario: Disabled by the configuration
- **WHEN** a configuration line is "plugin.explorer.enabled false" and `<leader>e` is pressed
- **THEN** no tree window opens
