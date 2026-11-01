## ADDED Requirements

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
