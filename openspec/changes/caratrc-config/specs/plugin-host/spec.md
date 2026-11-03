# Spec Delta

## MODIFIED Requirements

### Requirement: Subscriptions, bindings, and options are validated too
Every event subscription SHALL be a known event. A manifest's default bindings SHALL be a list of configuration lines of the form `keymap.<mode> <keys> <action>`, each of which SHALL parse and name one of the plugin's own actions or a key sequence. A manifest's option defaults SHALL be a list of configuration lines of the form `plugin.<name>.<option> <value>` with the plugin's own name, one per option, each option having a type among bool, integer, string, and list and a default value of that type. A broken rule disables the plugin as any other rule does.

#### Scenario: Unknown event
- **WHEN** a plugin subscribes to "idle"
- **THEN** validation reports the event

#### Scenario: Binding to a foreign action
- **WHEN** a plugin's default bindings hold the line "keymap.normal x cursor.down"
- **THEN** validation reports the binding

#### Scenario: Option default of the wrong type
- **WHEN** a plugin declares an integer option whose default line is "plugin.probe.size many"
- **THEN** validation reports the option

#### Scenario: Option default for another plugin
- **WHEN** a plugin named "probe" gives the default line "plugin.other.size 3"
- **THEN** validation reports the option line

### Requirement: The host refuses a newer major API version
The API SHALL have a version in `major.minor` form, 2.0 since the configuration files change made default bindings and option defaults lists of configuration lines. A manifest written against a different major version, or against the host's major version with a newer minor, SHALL be refused with a message naming the plugin, the version it needs, and the version the host has; a manifest with the same major and the host's minor or an older one SHALL be accepted.

#### Scenario: Newer major
- **WHEN** a plugin's manifest names API version "3.0"
- **THEN** the plugin is disabled and the host records that the plugin needs API 3.0 and the host has 2.0

#### Scenario: Older major
- **WHEN** a plugin's manifest names API version "1.3"
- **THEN** the plugin is disabled and the host records that it needs API 1.3

#### Scenario: Newer minor
- **WHEN** a plugin's manifest names API version "2.1"
- **THEN** the plugin is disabled and the host records that it needs API 2.1 and the host has 2.0

#### Scenario: Older minor
- **WHEN** a plugin's manifest names API version "2.0", the host's major with a minor no newer than the host's
- **THEN** the plugin is accepted

### Requirement: The configuration enables plugins
A `plugin.<name>.enabled` line SHALL take `true` or `false`, the last such line winning. A plugin whose last line sets it to false, from whatever configuration file, SHALL be registered but not activated: its bindings are not merged, its actions report that the plugin is disabled, and its ex commands are unknown. A plugin no line names SHALL be enabled. A `plugin.<name>` line for a plugin that is not registered SHALL be reported as `file:line: unknown plugin NAME`, except in the shipped defaults, which name every compiled plugin.

#### Scenario: Disabled in the configuration
- **WHEN** a configuration line is "plugin.hello.enabled false" and `<leader>hh` is pressed, then ":Hello" is run
- **THEN** nothing happens on the keys and the message is "E492: Not an editor command: Hello"

#### Scenario: Re-enabled by a later file
- **WHEN** the user file holds "plugin.hello.enabled false" and the project file "plugin.hello.enabled true"
- **THEN** the hello plugin is active

#### Scenario: Every plugin disabled
- **WHEN** every plugin is disabled, a file is opened, "x" is pressed, ":w" is run, and ":q" is run
- **THEN** the character is deleted, the file is written, and the editor quits

#### Scenario: Unknown plugin
- **WHEN** the project file's first line is "plugin.finder.enabled true" and no finder plugin is registered
- **THEN** ".caratrc:1: unknown plugin finder" is reported

### Requirement: The configuration sets plugin options
A `plugin.<name>.<option> <value>` line whose value is of the option's type SHALL replace the manifest default, the last such line winning. A line of the wrong type SHALL keep the earlier value and be reported as `file:line: plugin.NAME.OPTION takes ...` with the kind it takes; a line naming an option the plugin does not declare SHALL be reported as `file:line: plugin NAME has no option OPTION`. A list value reaches the plugin as its words joined by newlines.

#### Scenario: Option from the configuration
- **WHEN** a configuration line is "plugin.hello.greeting Hi" and ":Hello" is run
- **THEN** the message starts with the info icon followed by " Hi, world!"

#### Scenario: Option of the wrong type
- **WHEN** the project file's first line is `plugin.hello.greeting "Good day" again`
- **THEN** the greeting stays "Hello" and ".caratrc:1: plugin.hello.greeting takes one word" is reported

#### Scenario: Unknown option
- **WHEN** the project file's first line is "plugin.hello.volume 3"
- **THEN** ".caratrc:1: plugin hello has no option volume" is reported

### Requirement: Built-in plugins are registered from a generated list
The built-in plugins SHALL be listed in `config/plugins.caratrc` in order, one `plugin.<name> <path> <class>` line each, and the editor SHALL construct them from a generated registry with one explicit constructor per plugin. The registry SHALL be regenerated with the configuration mirror, and the test suite SHALL fail when it is out of date with `config/plugins.caratrc`.

#### Scenario: The explorer plugin is listed
- **WHEN** the editor starts with the shipped configuration
- **THEN** the `explorer` plugin is registered, enabled, and its actions and ex commands are available, and no `hello` plugin is registered

#### Scenario: Stale registry
- **WHEN** `config/plugins.caratrc` lists a plugin the generated registry does not construct
- **THEN** the config sync test fails naming the registry
