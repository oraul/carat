# plugin-host Specification

## Purpose
The plugin host is how compiled plugins become part of the editor: they are registered from a fixed list, validated, enabled from the configuration, given key bindings, actions, ex commands, events, and a set of requests that read and change the editor through values only, and kept from ending the editor or corrupting a buffer when they fail.

## Requirements

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
Every event subscription SHALL be a known event. A manifest's default bindings SHALL be `keymap.<mode> <keys> <action>` configuration lines that parse and name one of the plugin's own actions or a key sequence. Its option defaults SHALL be `plugin.<name>.<option> <value>` lines with the plugin's own name, one per option, each option typed bool, integer, string, or list with a default of that type. A broken rule disables the plugin as any other rule does.

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
A `plugin.<name>.enabled` line SHALL take `true` or `false`, the last one winning. A plugin whose last line sets false, from any file, SHALL be registered but not activated: its bindings are not merged, its actions report that it is disabled, and its ex commands are unknown. A plugin no line names SHALL be enabled. A line for an unregistered plugin SHALL be reported as `file:line: unknown plugin NAME`, except in the shipped defaults.

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

### Requirement: Plugin actions are routed to their plugin with the typed count
An action named `plugin.<name>.<action>` SHALL complete at once in normal mode, as the other standalone actions do, and SHALL be delivered to the plugin named in it with the count and register typed before it, the current buffer and window ids, the path, and the cursor. An action for an unregistered plugin SHALL report that no such plugin exists; one for a disabled plugin SHALL report that the plugin is disabled.

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
An ex command a plugin declares SHALL be run by the plugin when typed as its abbreviation, its full name, or any spelling between them that starts the full name, with its bang and arguments, after the core ex commands and before the unknown-command check; when two plugins' commands accept the typed name, the plugin registered first SHALL run it. Its result message SHALL be shown as another ex command's is.

#### Scenario: Full name
- **WHEN** ":Hello Ada" is run
- **THEN** the message row ends with "Hello, Ada! 1 buffer opened"

#### Scenario: Abbreviation
- **WHEN** ":Hel" is run
- **THEN** the hello plugin greets as ":Hello" does

#### Scenario: Between the abbreviation and the full name
- **WHEN** ":Hell" is run
- **THEN** the hello plugin greets as ":Hello" does

#### Scenario: Shorter than the abbreviation
- **WHEN** ":He" is run
- **THEN** the message is "E492: Not an editor command: He"

### Requirement: Events are delivered as values after the key that caused them
After a key has been handled, the host SHALL deliver to every subscribed plugin, in registration order, the events the key caused: first the buffer events in the order they happened (`buffer_open`, `buffer_change`, `buffer_save`, `buffer_rename`, `buffer_close`), then `cursor_move` when the cursor or the current buffer changed, `mode_change` when the mode changed, `window_focus` when the current window or tab page changed, and `quit` when the editor is about to end.

#### Scenario: Opening a file
- **WHEN** a test plugin subscribed to every event is active and ":e b.txt" is run over a clean buffer
- **THEN** it receives buffer_open for the new buffer, buffer_close for the buffer it replaced, then cursor_move, in that order

#### Scenario: Editing
- **WHEN** "x" is pressed in a buffer with text
- **THEN** the plugin receives buffer_change then cursor_move, and no mode_change

#### Scenario: Reloading the current buffer
- **WHEN** a test plugin subscribed to every event is active and ":e!" is run on the current buffer
- **THEN** the plugin receives buffer_change

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
`buffer_save` SHALL be delivered when a buffer is written and `resize` when the editor is drawn at a new size. Every event SHALL carry its name as a string, the buffer id, the window id, the path, and the cursor, or the rows and columns for a resize.

#### Scenario: Saving
- **WHEN** ":w" is run on a modified buffer
- **THEN** the plugin receives buffer_save with the buffer's path

#### Scenario: Resizing
- **WHEN** the terminal becomes 30 rows by 100 columns
- **THEN** the plugin receives resize with row 30 and col 100

### Requirement: A plugin reads buffers, moves the cursor, and shows messages through requests
A plugin SHALL read a buffer by id, 0 for the current one, as its lines, path, cursor, and modified flag, with a failed response for an id no listed buffer has; SHALL move the cursor of the current window to a row and column clamped into the buffer; SHALL show a message, plain or error; SHALL set its own status segment; and SHALL run an ex command string and receive its outcome.

#### Scenario: Read the current buffer
- **WHEN** a test plugin reads buffer 0 while "a.txt" holds ["one", "two"] with the cursor on row 1
- **THEN** it receives the lines, the path "a.txt", the buffer's id, the cursor (1, 0), and modified false

#### Scenario: Read a missing buffer
- **WHEN** a test plugin reads buffer 99 with two buffers listed
- **THEN** the response is failed with "No buffer 99"

#### Scenario: Move the cursor
- **WHEN** a test plugin moves the cursor to row 1 column 50 in a buffer whose row 1 has three characters
- **THEN** the cursor is at (1, 2)

#### Scenario: Run an ex command
- **WHEN** a test plugin runs the ex command "w"
- **THEN** the file is written and the response carries the written message

### Requirement: Edits are applied as one validated transaction
A plugin SHALL edit a buffer with a list of replacements, each a start, an exclusive end, and the text to put there. The host SHALL validate every item before changing any line and SHALL refuse the whole list, naming the first bad item, when an item is not an edit, a position is outside the buffer, an end precedes its start, or the edits overlap or are out of order; otherwise it SHALL apply them all as one transaction.

#### Scenario: Two edits
- **WHEN** a test plugin replaces columns 0 to 3 of row 0 with "ONE" and inserts "!" at the end of row 1 in ["one", "two"]
- **THEN** the buffer holds ["ONE", "two!"] and is modified

#### Scenario: One bad edit refuses all
- **WHEN** the list holds a valid edit and an edit whose row is past the last line
- **THEN** the response is failed, its message names edit 2, and the buffer is unchanged

#### Scenario: A bad last item
- **WHEN** the list holds two valid edits and then a value that is not an edit
- **THEN** the response is failed with "edit 3: not an edit", the buffer is unchanged, and no change event is delivered

#### Scenario: Overlapping edits
- **WHEN** two edits of one request overlap
- **THEN** the response is failed and the buffer is unchanged

### Requirement: A plugin places and clears signs
A plugin SHALL place a sign, an icon by name, on a row of a buffer, replacing its own sign on that row and never another plugin's, and SHALL clear the signs it placed in a buffer without touching another plugin's. When two plugins mark one row, the sign of the plugin registered first SHALL show. A row outside the buffer SHALL be refused.

#### Scenario: Place and clear
- **WHEN** a test plugin places the "error" sign on row 1 and then clears its signs
- **THEN** the buffer has one sign on row 1 after placing and none after clearing

#### Scenario: Another plugin's sign stays
- **WHEN** two plugins place signs on different rows and one clears its signs
- **THEN** the other plugin's sign stays

#### Scenario: Two plugins on one row
- **WHEN** the plugin registered second places "warning" on row 0 and then the plugin registered first places "error" there, and the first clears its signs
- **THEN** row 0 shows the error glyph while both are placed and the warning glyph after the clear

### Requirement: A plugin reads the file system and the icon table through the host
A plugin SHALL list a directory's entries in sorted order and read the size, modification time, directory flag, and symbolic link flag of a path through the host, with a failed response when the port raises; SHALL ask for an icon by name and receive the glyph of the configured set, or a failed response naming an unknown icon; and SHALL read its own option values as text, with a failed response for an unknown option.

#### Scenario: Directory listing
- **WHEN** a test plugin lists a directory holding "b.txt" and "a.txt"
- **THEN** it receives ["a.txt", "b.txt"]

#### Scenario: Symbolic link
- **WHEN** a test plugin stats a path that is a symbolic link to a directory
- **THEN** the answer has directory true and symlink true

#### Scenario: Icon by name
- **WHEN** the icons option is "ascii" and a plugin asks for the "folder_closed" icon
- **THEN** it receives "+"

#### Scenario: Unknown icon
- **WHEN** a plugin asks for the icon "nope"
- **THEN** the response is failed with "No icon named nope"

#### Scenario: Option as text
- **WHEN** the explorer plugin reads its "width" option with the shipped configuration
- **THEN** it receives "30"

### Requirement: A failing plugin is disabled and the editor keeps running
When a plugin raises anything while being registered, activated, or deactivated, or while handling an action, an ex command, an event, or an input, including `NotImplementedError` and a stack overflow, the host SHALL disable it, show "Plugin <name> disabled: <error>" in the message row as an error, and go on handling keys; the buffer SHALL be as it was before the plugin's call.

#### Scenario: Raise in an action
- **WHEN** a test plugin raises "boom" in its action and the key bound to it is pressed, then "x" is pressed
- **THEN** the message row read "Plugin boom disabled: boom" after the first key and the character is deleted by the second

#### Scenario: Raise in an event
- **WHEN** a test plugin raises in on_event and "x" is pressed
- **THEN** the character is deleted, the plugin is disabled, and later keys deliver it nothing

#### Scenario: An unimplemented host method
- **WHEN** a test plugin calls a host method its host does not implement in its action
- **THEN** the plugin is disabled with the NotImplementedError message and the editor keeps running

#### Scenario: A stack overflow
- **WHEN** a test plugin recurses without end in its action
- **THEN** the plugin is disabled with "stack level too deep" and the editor keeps running

### Requirement: Built-in plugins are registered from a generated list
The built-in plugins SHALL be listed in `config/plugins.caratrc` in order, one `plugin.<name> <path> <class>` line each, and the editor SHALL construct them from a generated registry with one explicit constructor per plugin. The registry SHALL be regenerated with the configuration mirror, and the test suite SHALL fail when it is out of date with `config/plugins.caratrc`.

#### Scenario: The explorer plugin is listed
- **WHEN** the editor starts with the shipped configuration
- **THEN** the `explorer` plugin is registered, enabled, and its actions and ex commands are available, and no `hello` plugin is registered

#### Scenario: Stale registry
- **WHEN** `config/plugins.caratrc` lists a plugin the generated registry does not construct
- **THEN** the config sync test fails naming the registry

### Requirement: A plugin reads the working directory and window numbers
A plugin SHALL read the editor's working directory as an absolute path; SHALL ask for the id of the window of the current tab page that shows its scratch buffer of a title, 0 when none does; and SHALL ask for the editing window, which is the previously used window when it shows a file buffer, otherwise the first window in layout order that does, 0 when none does.

#### Scenario: Working directory
- **WHEN** the editor runs in "/home/ada/proj" and a plugin asks for the working directory
- **THEN** it receives "/home/ada/proj"

#### Scenario: Scratch window number
- **WHEN** a plugin's scratch buffer "list" is shown and the plugin asks for the window of "list"
- **THEN** the answer is the id of the side window, and for a title it does not show the answer is 0

#### Scenario: Editing window
- **WHEN** the side window is current and the previously used window shows "a.txt"
- **THEN** the editing window is that window's id

#### Scenario: No editing window
- **WHEN** the only window shows a scratch buffer
- **THEN** the editing window is 0

### Requirement: A plugin creates files and directories inside a root
A plugin SHALL create an empty file or a directory at a path inside a root it names. The host SHALL refuse, with a failed response and no change on disk, a path that is not strictly inside the root after resolving "." and "..", a path whose last name is empty, ".", or "..", a path that already exists, and a path whose parent directory does not exist.

#### Scenario: Create a file
- **WHEN** a plugin creates "/w/new.rb" under the root "/w"
- **THEN** the response succeeded and "/w/new.rb" exists and is empty

#### Scenario: Create a directory
- **WHEN** a plugin creates the directory "/w/pkg" under the root "/w"
- **THEN** "/w/pkg" is a directory

#### Scenario: Outside the root
- **WHEN** a plugin creates "/w/../etc/x" under the root "/w"
- **THEN** the response is failed with "Outside the tree root: /etc/x" and nothing is created

#### Scenario: Existing target
- **WHEN** a plugin creates "/w/a.txt" while it exists
- **THEN** the response is failed with "Already exists: a.txt"

#### Scenario: Missing parent
- **WHEN** a plugin creates "/w/no/x.rb" and "/w/no" does not exist
- **THEN** the response is failed with "No such directory: no"

### Requirement: A plugin renames an entry inside a root
A plugin SHALL rename a file or directory strictly inside a root to a new name in the same directory. The host SHALL refuse an empty name, "." or "..", a name containing "/", a missing source, the root itself, and an existing target, with a failed response and no change on disk. A listed buffer whose file is the renamed path, or lies under a renamed directory, SHALL show the new path, relative to the working directory when it was.

#### Scenario: Rename a file
- **WHEN** a plugin renames "/w/a.txt" to "b.txt" under the root "/w"
- **THEN** "/w/b.txt" exists, "/w/a.txt" does not, and the response succeeded

#### Scenario: Path separator
- **WHEN** a plugin renames "/w/a.txt" to "x/b.txt"
- **THEN** the response is failed with "Name contains a path separator: x/b.txt"

#### Scenario: Open buffer follows
- **WHEN** "a.txt" is open as "a.txt" and a plugin renames it to "c.txt"
- **THEN** the buffer's path is "c.txt" and it is not modified

#### Scenario: Buffer under a renamed directory
- **WHEN** "lib/x.rb" is open and a plugin renames "/w/lib" to "src"
- **THEN** the buffer's path is "src/x.rb"

### Requirement: A plugin deletes a file or an empty directory inside a root
A plugin SHALL delete a file or an empty directory strictly inside a root; a directory with entries SHALL be refused with "Directory not empty: <path>" and nothing is deleted, and there SHALL be no recursive delete. A listed buffer of a deleted file SHALL stay in the list and become modified.

#### Scenario: Delete a file
- **WHEN** a plugin deletes "/w/a.txt" under the root "/w"
- **THEN** "/w/a.txt" no longer exists

#### Scenario: Non-empty directory
- **WHEN** a plugin deletes "/w/lib", which holds "x.rb"
- **THEN** the response is failed with "Directory not empty: lib" and "/w/lib/x.rb" still exists

#### Scenario: Open buffer becomes modified
- **WHEN** "a.txt" is open and a plugin deletes it
- **THEN** the buffer is still listed and modified, and ":q" on it reports E37

### Requirement: A plugin asks for input on the command line
A plugin SHALL show a prompt with an id, a text, and an initial value: the editor SHALL enter command-line mode with the prompt text in place of ":" followed by the initial value, the command-line keys SHALL edit it, Enter SHALL deliver the edited text to the plugin with the id, and Escape or a backspace on an empty line SHALL deliver a cancel with the id, both returning to normal mode. A prompt while another is open SHALL be refused.

#### Scenario: Answer
- **WHEN** a test plugin prompts "Name: " with the initial value "a" and "bc" Enter is typed
- **THEN** the message row read "Name: abc" before Enter and the plugin receives the text "abc" with its id, not cancelled

#### Scenario: Cancel
- **WHEN** a test plugin prompts and Escape is pressed
- **THEN** the plugin receives a cancel with its id and the mode is normal

#### Scenario: Not an ex command
- **WHEN** a test plugin prompts and "q" Enter is typed
- **THEN** the editor is still running

### Requirement: A broken manifest disables its plugin at startup
A plugin whose manifest cannot be read, because reading it raises or a member has the wrong type, SHALL be registered disabled with the reason, and the editor SHALL start; a manifest that raises SHALL be registered under the name `plugin<N>`, its position in the plugin list.

#### Scenario: Manifest raises
- **WHEN** the second plugin of the list does not implement its manifest
- **THEN** the editor starts, `plugin2` is registered disabled with the NotImplementedError message, and the other plugins are enabled

#### Scenario: Member of the wrong type
- **WHEN** a plugin's manifest gives a string where its actions should be
- **THEN** the plugin is disabled with "actions is not an object of action names" and the editor starts

### Requirement: Plugin names and ex commands are unique
A plugin whose name is already registered, or that declares an ex command name or abbreviation an enabled plugin registered before it declares, SHALL be registered disabled with the reason, and the first plugin SHALL keep its name and its command.

#### Scenario: Duplicate name
- **WHEN** two plugins named "probe" are registered
- **THEN** the second is disabled with "a plugin named probe is already registered" and the first is enabled

#### Scenario: Duplicate ex command
- **WHEN** two plugins both declare ":Probe"
- **THEN** the second is disabled with "command Probe is already declared by plugin probe" and ":Probe" reaches the first

### Requirement: Conflicting default bindings are reported
When a plugin's default binding uses keys of a mode that a plugin activated before it already binds, the first plugin SHALL keep the keys and the conflict SHALL be recorded in the host's errors, naming the mode, the keys, and both plugins.

#### Scenario: Two plugins bind the same keys
- **WHEN** two plugins both bind `<leader>pp` in normal mode by default
- **THEN** `<leader>pp` runs the first plugin's action and the errors hold "plugin other: binding normal.<leader>pp is already bound by plugin probe"

### Requirement: Buffer changes carry the changed rows
`buffer_change` SHALL be delivered once per closed transaction, for every buffer that changed, including a buffer that is not current and one another plugin changed, with the buffer id, the first changed row, the number of rows removed there, and the number of rows inserted in their place.

#### Scenario: Deleting a line
- **WHEN** "dd" is pressed on row 1 of a three-line buffer
- **THEN** buffer_change carries row 1, 1 row removed, and 0 rows inserted

#### Scenario: Another plugin's edit
- **WHEN** plugin A inserts a line into a buffer that is not current from its action
- **THEN** plugin B receives buffer_change with that buffer's id and the inserted row, and plugin A does not

### Requirement: Closing and renaming buffers are events
`buffer_close` SHALL be delivered when a buffer leaves the buffer list, with its id and its path, and `buffer_rename` when a listed buffer's path changes, with the new path and the old path in the detail.

#### Scenario: Close
- **WHEN** a split shows "b.txt", a clean buffer no other window shows, and that window is closed
- **THEN** the plugin receives buffer_close with the buffer's id and "b.txt"

#### Scenario: Rename
- **WHEN** a plugin renames the open file "a.txt" to "c.txt"
- **THEN** another plugin receives buffer_rename with the path "c.txt" and the detail "a.txt"

### Requirement: Events caused during a plugin call are queued
While a plugin call is running, the events it causes SHALL be queued and delivered after the outermost plugin call returns, to every subscribed plugin except the one whose request caused them; events queued while delivering are delivered in the next round, and after 8 rounds the rest SHALL be dropped with a message.

#### Scenario: Writing on save does not recurse
- **WHEN** a test plugin runs ":w" whenever it receives buffer_save and ":w" is typed
- **THEN** the file is written twice, the plugin receives one buffer_save, and the editor keeps running

#### Scenario: Two plugins writing on each other's saves
- **WHEN** two test plugins each run ":w" on every buffer_save and ":w" is typed
- **THEN** the message row reads "Plugin events dropped after 8 rounds" and the editor keeps running

### Requirement: Nested plugin commands are limited
An ex command a plugin runs while plugin calls are nested 4 deep SHALL be refused with "E169: Command too recursive" and nothing run.

#### Scenario: A command that runs itself
- **WHEN** a test plugin's ex command runs itself through the host and the user runs it
- **THEN** the plugin's command ran 4 times, the innermost request was refused with "E169: Command too recursive", and the editor keeps running

### Requirement: Signs move with their lines
A sign SHALL stay on the line it was placed on when lines are inserted or deleted above it, and SHALL go away with its line when that line is deleted; editing the text of its line SHALL keep it.

#### Scenario: Lines inserted above
- **WHEN** a sign is on row 2 and "O" then Escape is pressed on row 0
- **THEN** the sign is on row 3

#### Scenario: Its line deleted
- **WHEN** a sign is on row 1 and "dd" is pressed on row 1
- **THEN** the buffer has no sign

### Requirement: Strings crossing the plugin boundary are copies
The lines and paths a plugin receives, and the lines it gives for a scratch buffer, SHALL be copies, so changing them in place changes nothing in the editor and changing the editor changes nothing a plugin holds.

#### Scenario: Changing a read line
- **WHEN** a test plugin reads the current buffer and appends "!" to its first line in place
- **THEN** the buffer's first line is unchanged

#### Scenario: Changing a given line
- **WHEN** a test plugin opens a scratch buffer with the line "x" and then appends "!" to its own string
- **THEN** the scratch buffer still shows "x"

### Requirement: A disabled plugin leaves nothing behind
When a plugin is disabled, also when its activation raises, the host SHALL close the windows of its scratch buffers and drop them from the list, remove its signs and its status segment, cancel its open prompt, and remove the key bindings its manifest added.

#### Scenario: Disabled with a side window open
- **WHEN** a test plugin with an open side window, a sign, an open prompt, and a default binding raises in an action
- **THEN** one window is left, the buffer has no sign, the mode is normal, and its binding no longer runs anything

### Requirement: A plugin can run ex commands while activating
A plugin SHALL be able to run an ex command string from its activation, with the same outcome as later.

#### Scenario: Tab page in activate
- **WHEN** a test plugin runs "tabnew" while activating and the editor opens "a.txt"
- **THEN** the run succeeded and the editor starts with two tab pages

### Requirement: Undo and redo reach plugins as buffer changes
An undo or redo SHALL be delivered to plugins as one `buffer_change` per key, with the first changed row and the rows removed and inserted there, like any other change.

#### Scenario: Undoing a deleted line
- **WHEN** "dd" is pressed on row 1 of a three-line buffer and then "u"
- **THEN** a subscribed plugin receives buffer_change with row 1, 0 rows removed, and 1 row inserted after "u"

### Requirement: A plugin edit request is undone in one step
The replacements of one plugin edit request made outside a command SHALL be undone and redone together by one "u" or "<C-r>".

#### Scenario: Two replacements, one undo
- **WHEN** a plugin replaces a character on rows 0 and 1 of ["ab", "cd"] in one request from an event, then "u" is pressed
- **THEN** the lines are ["ab", "cd"]

### Requirement: A plugin declares the filetypes it tokenizes
A manifest SHALL list the filetypes the plugin tokenizes, each lowercase letters, digits, and underscores starting with a letter, or none; another value SHALL refuse the plugin with the rule it broke. When two enabled plugins declare one filetype, the one registered first tokenizes it.

#### Scenario: Malformed filetype
- **WHEN** a manifest lists the filetype `Ruby Script`
- **THEN** the plugin is disabled with a reason naming the filetype

#### Scenario: Two plugins for one filetype
- **WHEN** two enabled plugins declare `ruby`
- **THEN** the plugin registered first tokenizes Ruby buffers

### Requirement: A tokenizer is called per line with the state before it
The host SHALL tokenize a line by calling the plugin with the filetype, a copy of the line's text, and the state at the start of the line (0 for the first line), and the plugin SHALL append its tokens to an integer array as (start column, length, group id) triples in code point columns and return the state at the end of the line, a non-negative integer.

#### Scenario: Tokens and state
- **WHEN** a plugin appends 0, 3, and the Define id for the line `def x` and returns 0
- **THEN** the cells of `def` are in the Define group and the next line starts in state 0

### Requirement: Malformed tokens and states are ignored
A token with a negative start, a length below one, or an id outside the syntax groups SHALL be ignored, and a returned state that is not a non-negative integer SHALL count as 0.

#### Scenario: A token out of range
- **WHEN** a plugin appends a token with the group id 9999
- **THEN** the token is ignored and the line is drawn in the normal group

#### Scenario: A negative state
- **WHEN** a plugin returns -5 as the end state of a line
- **THEN** the next line is tokenized starting in state 0

### Requirement: A plugin resolves highlight group names through the host
`syntax_group(name)` SHALL answer the id of a syntax group by its name, as a successful response whose number is the id, and fail with `No highlight group named <name>` for any other name.

#### Scenario: Resolving a group
- **WHEN** a plugin asks for `String` while activating
- **THEN** the response succeeds and its number is the String group's id

### Requirement: A tokenizer that raises disables its plugin
A tokenizer call SHALL be guarded like every plugin call: a plugin whose tokenizer raises SHALL be disabled with its message in the message row, and every buffer it tokenized SHALL be drawn in the normal group from the same frame on.

#### Scenario: Raising tokenizer
- **WHEN** a plugin's tokenizer raises while a buffer of its filetype is drawn
- **THEN** the message row shows `Plugin <name> disabled: <message>` and the buffer is drawn in the normal group

### Requirement: A create request never goes through a link that leaves the root
The host SHALL refuse a create request, a file or a directory, with `Outside the tree root: path` and no change on disk, when the parent directory of the path, with every symbolic link resolved, is neither the root with its links resolved nor inside it. A link inside the root that resolves inside it SHALL still be created through.

#### Scenario: Linked parent leading outside
- **WHEN** "/w/out" is a symbolic link to "/elsewhere" and a plugin creates "/w/out/x.rb" under the root "/w"
- **THEN** the response is failed with "Outside the tree root: out/x.rb" and "/elsewhere/x.rb" does not exist

#### Scenario: Linked parent staying inside
- **WHEN** "/w/alias" is a symbolic link to "/w/lib" and a plugin creates "/w/alias/x.rb" under the root "/w"
- **THEN** the response succeeded and "/w/lib/x.rb" exists

#### Scenario: Linked root
- **WHEN** the root "/w" is itself a symbolic link to "/real" and a plugin creates "/w/new.rb"
- **THEN** the response succeeded
