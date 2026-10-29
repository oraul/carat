# plugin-host Specification

## Purpose
The plugin host is how compiled plugins become part of the editor: they are registered from a fixed list, validated, enabled from the configuration, given key bindings, actions, ex commands, events, and a set of requests that read and change the editor through values only, and kept from ending the editor or corrupting a buffer when they fail.

## Requirements

### Requirement: Compiled plugins are registered from a generated list
The built-in plugins SHALL be listed in `config/plugins.json` in order, and the editor SHALL construct them from a generated registry with one explicit constructor per plugin. The registry SHALL be regenerated with the configuration mirror, and the test suite SHALL fail when it is out of date with `config/plugins.json`.

#### Scenario: The hello plugin is listed
- **WHEN** the editor starts with the shipped configuration
- **THEN** the `hello` plugin is registered, enabled, and its action and ex command are available

#### Scenario: Stale registry
- **WHEN** `config/plugins.json` lists a plugin the generated registry does not construct
- **THEN** the config sync test fails naming the registry

### Requirement: A manifest is validated at registration
A plugin whose manifest breaks a rule SHALL be registered as disabled with a message naming the plugin and the rule, and nothing of it SHALL be bound or routed. The name SHALL be lowercase letters, digits, and underscores starting with a letter; every action SHALL be named `plugin.<name>.<action>` with the plugin's own name and have a description; every ex command SHALL start with an uppercase letter with an abbreviation that is empty or a proper prefix of it.

#### Scenario: Action named for another plugin
- **WHEN** a plugin named "a" declares the action "plugin.b.go"
- **THEN** validation reports the action and the plugin is disabled

#### Scenario: Lowercase ex command
- **WHEN** a plugin declares the ex command "hello"
- **THEN** validation reports the command

#### Scenario: Valid manifest
- **WHEN** the hello plugin's manifest is checked
- **THEN** no rule is reported

### Requirement: Subscriptions, bindings, and options are validated too
Every event subscription SHALL be a known event; every default binding SHALL parse and name one of the plugin's own actions or a key sequence; every option SHALL have a type among bool, integer, string, and list and a default of that type. A broken rule disables the plugin as any other rule does.

#### Scenario: Unknown event
- **WHEN** a plugin subscribes to "idle"
- **THEN** validation reports the event

#### Scenario: Binding to a foreign action
- **WHEN** a plugin's default bindings map a key to "cursor.down"
- **THEN** validation reports the binding

#### Scenario: Option default of the wrong type
- **WHEN** a plugin declares an integer option whose default is "many"
- **THEN** validation reports the option

### Requirement: The host refuses a newer major API version
The API SHALL have a version in `major.minor` form, 1.0 in this change. A manifest written against a greater major version SHALL be refused with a message naming the plugin, the version it needs, and the version the host has; a manifest with the same major and any minor SHALL be accepted.

#### Scenario: Newer major
- **WHEN** a plugin's manifest names API version "2.0"
- **THEN** the plugin is disabled and the message row shows that the plugin needs API 2.0 and the host has 1.0

#### Scenario: Newer minor
- **WHEN** a plugin's manifest names API version "1.3"
- **THEN** the plugin is accepted

### Requirement: The configuration enables plugins
The `plugins` object of the configuration SHALL have one entry per plugin name with `enabled` and `options`. A plugin whose entry sets `enabled` to false, from whatever configuration file, SHALL be registered but not activated: its bindings are not merged, its actions report that the plugin is disabled, and its ex commands are unknown. A plugin with no entry SHALL be enabled.

#### Scenario: Disabled in the configuration
- **WHEN** the configuration sets plugins.hello.enabled to false and `<leader>hh` is pressed, then ":Hello" is run
- **THEN** nothing happens on the keys and the message is "E492: Not an editor command: Hello"

#### Scenario: Every plugin disabled
- **WHEN** every plugin is disabled, a file is opened, "x" is pressed, ":w" is run, and ":q" is run
- **THEN** the character is deleted, the file is written, and the editor quits

### Requirement: The configuration sets plugin options
An option value of the right type in a plugin's `options` entry SHALL replace the manifest default; one of the wrong type SHALL keep the default and be recorded.

#### Scenario: Option from the configuration
- **WHEN** the configuration sets plugins.hello.options.greeting to "Hi" and ":Hello" is run
- **THEN** the message starts with the info icon followed by " Hi, world!"

#### Scenario: Option of the wrong type
- **WHEN** the configuration sets plugins.hello.options.greeting to 7
- **THEN** the greeting stays "Hello" and the host records the option

### Requirement: Plugin actions are routed to their plugin with the typed count
An action named `plugin.<name>.<action>` SHALL complete at once in normal mode, as the other standalone actions do, and SHALL be delivered to the plugin named in it with the count and register typed before it, the current buffer and window numbers, the path, and the cursor. An action for an unregistered plugin SHALL report that no such plugin exists; one for a disabled plugin SHALL report that the plugin is disabled.

#### Scenario: Default binding of the hello plugin
- **WHEN** `<leader>hh` is pressed with the shipped configuration
- **THEN** the message row shows the info icon, then " Hello, world! 1 buffer opened"

#### Scenario: Count reaches the plugin
- **WHEN** "3<leader>hh" is typed with a test plugin that records its context
- **THEN** the plugin receives the count 3

#### Scenario: Unknown plugin
- **WHEN** a key bound to "plugin.nope.go" is pressed
- **THEN** the message row reads "No plugin named nope"

### Requirement: Plugin ex commands are routed by name or abbreviation
An ex command a plugin declares SHALL be run by the plugin when typed by its full name or its abbreviation, with its bang and arguments, before the unknown-command check; its result message SHALL be shown as another ex command's is.

#### Scenario: Full name
- **WHEN** ":Hello Ada" is run
- **THEN** the message row ends with "Hello, Ada! 1 buffer opened"

#### Scenario: Abbreviation
- **WHEN** ":Hel" is run
- **THEN** the hello plugin greets as ":Hello" does

### Requirement: Events are delivered as values after the key that caused them
After a key has been handled, the host SHALL deliver to every subscribed plugin, in registration order, the events the key caused, in this order: `buffer_open` for each buffer that entered the list, `buffer_change` when the current buffer's text changed, `cursor_move` when the cursor or the current buffer changed, `mode_change` when the mode changed, `window_focus` when the current window or tab page changed, and `quit` when the editor is about to end.

#### Scenario: Opening a file
- **WHEN** a test plugin subscribed to every event is active and ":e b.txt" is run
- **THEN** it receives buffer_open for the new buffer, then cursor_move, in that order

#### Scenario: Editing
- **WHEN** "x" is pressed in a buffer with text
- **THEN** the plugin receives buffer_change then cursor_move, and no mode_change

#### Scenario: Entering insert mode
- **WHEN** "i" is pressed
- **THEN** the plugin receives mode_change with the detail "insert"

#### Scenario: Quitting
- **WHEN** ":q" is run on a clean buffer
- **THEN** the plugin receives quit and then its deactivate is called

#### Scenario: Unsubscribed events are not delivered
- **WHEN** the hello plugin, subscribed only to buffer_open, is active and "x" is pressed
- **THEN** the hello plugin receives nothing

### Requirement: Saves and resizes are events too
`buffer_save` SHALL be delivered when a buffer is written and `resize` when the editor is drawn at a new size. Every event SHALL carry its name, the buffer number, the window number, the path, and the cursor, or the rows and columns for a resize.

#### Scenario: Saving
- **WHEN** ":w" is run on a modified buffer
- **THEN** the plugin receives buffer_save with the buffer's path

#### Scenario: Resizing
- **WHEN** the terminal becomes 30 rows by 100 columns
- **THEN** the plugin receives resize with row 30 and col 100

### Requirement: A plugin reads buffers, moves the cursor, and shows messages through requests
A plugin SHALL read a buffer by number, 0 for the current one, as its lines, path, cursor, and modified flag, with a failed response for a number outside the list; SHALL move the cursor of the current window to a row and column clamped into the buffer; SHALL show a message, plain or error; SHALL set its own status segment; and SHALL run an ex command string and receive its outcome.

#### Scenario: Read the current buffer
- **WHEN** a test plugin reads buffer 0 while "a.txt" holds ["one", "two"] with the cursor on row 1
- **THEN** it receives the lines, the path "a.txt", the cursor (1, 0), and modified false

#### Scenario: Read a missing buffer
- **WHEN** a test plugin reads buffer 9 with two buffers listed
- **THEN** the response is failed

#### Scenario: Move the cursor
- **WHEN** a test plugin moves the cursor to row 1 column 50 in a buffer whose row 1 has three characters
- **THEN** the cursor is at (1, 2)

#### Scenario: Run an ex command
- **WHEN** a test plugin runs the ex command "w"
- **THEN** the file is written and the response carries the written message

### Requirement: Edits are applied as one validated transaction
A plugin SHALL edit a buffer with a list of replacements, each a start, an exclusive end, and the text to put there. The host SHALL validate every edit before changing any line and SHALL refuse the whole list, naming the first bad edit, when a position is outside the buffer, an end precedes its start, or the edits overlap or are out of ascending order; otherwise it SHALL apply them all, mark the buffer modified, and keep every cursor on the buffer inside its text.

#### Scenario: Two edits
- **WHEN** a test plugin replaces columns 0 to 3 of row 0 with "ONE" and inserts "!" at the end of row 1 in ["one", "two"]
- **THEN** the buffer holds ["ONE", "two!"] and is modified

#### Scenario: One bad edit refuses all
- **WHEN** the list holds a valid edit and an edit whose row is past the last line
- **THEN** the response is failed, its message names edit 2, and the buffer is unchanged

#### Scenario: Overlapping edits
- **WHEN** two edits of one request overlap
- **THEN** the response is failed and the buffer is unchanged

### Requirement: A plugin places and clears signs
A plugin SHALL place a sign, an icon by name, on a row of a buffer, replacing a sign already on that row, and SHALL clear the signs it placed in a buffer without touching another plugin's. A row outside the buffer SHALL be refused.

#### Scenario: Place and clear
- **WHEN** a test plugin places the "error" sign on row 1 and then clears its signs
- **THEN** the buffer has one sign on row 1 after placing and none after clearing

#### Scenario: Another plugin's sign stays
- **WHEN** two plugins place signs on different rows and one clears its signs
- **THEN** the other plugin's sign stays

### Requirement: A plugin reads the file system and the icon table through the host
A plugin SHALL list a directory's entries in sorted order and read the size, modification time, and directory flag of a path through the host, with a failed response when the port raises; SHALL ask for an icon by name and receive the glyph of the configured set; and SHALL read its own option values as text.

#### Scenario: Directory listing
- **WHEN** a test plugin lists a directory holding "b.txt" and "a.txt"
- **THEN** it receives ["a.txt", "b.txt"]

#### Scenario: Icon by name
- **WHEN** the icons option is "ascii" and a plugin asks for the "folder_closed" icon
- **THEN** it receives "+"

#### Scenario: Option as text
- **WHEN** the hello plugin reads its "greeting" option with the shipped configuration
- **THEN** it receives "Hello"

### Requirement: A failing plugin is disabled and the editor keeps running
When a plugin raises while being activated or while handling an action, an ex command, or an event, the host SHALL disable it, show "Plugin <name> disabled: <error>" in the message row as an error, and go on. The editor SHALL keep handling keys, and the buffer SHALL be as it was before the plugin's call, since every edit is validated before any line changes.

#### Scenario: Raise in an action
- **WHEN** a test plugin raises "boom" in its action and the key bound to it is pressed, then "x" is pressed
- **THEN** the message row read "Plugin boom disabled: boom" after the first key, the character is deleted by the second, and the plugin's action now reports that the plugin is disabled

#### Scenario: Raise in an event
- **WHEN** a test plugin raises in on_event and "x" is pressed
- **THEN** the character is deleted, the plugin is disabled, and later keys deliver it nothing
