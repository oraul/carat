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
The API SHALL have a version in `major.minor` form, 2.2 since the `set_segment` request lets a plugin give its status bar segment a priority. A manifest written against a different major version, or against the host's major version with a newer minor, SHALL be refused with a message naming the plugin, the version it needs, and the version the host has; a manifest with the same major and the host's minor or an older one SHALL be accepted.

#### Scenario: Newer major
- **WHEN** a plugin's manifest names API version "3.0"
- **THEN** the plugin is disabled and the host records that the plugin needs API 3.0 and the host has 2.2

#### Scenario: Older major
- **WHEN** a plugin's manifest names API version "1.3"
- **THEN** the plugin is disabled and the host records that it needs API 1.3

#### Scenario: Newer minor
- **WHEN** a plugin's manifest names API version "2.3"
- **THEN** the plugin is disabled and the host records that it needs API 2.3 and the host has 2.2

#### Scenario: Older minor
- **WHEN** a plugin's manifest names API version "2.1", the host's major with a minor older than the host's
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
A plugin SHALL be able to run an ex command string from its activation, at its first trigger, with the same outcome as later.

#### Scenario: Tab page in activate
- **WHEN** a test plugin runs "tabnew" while activating and the key bound to its action is pressed
- **THEN** the run succeeded and the editor has two tab pages

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
A token with a negative start, a length below one, or an id outside the syntax groups and the file-icon groups SHALL be ignored, and a returned state that is not a non-negative integer SHALL count as 0.

#### Scenario: A token out of range
- **WHEN** a plugin appends a token with the group id 9999
- **THEN** the token is ignored and the line is drawn in the normal group

#### Scenario: A token in an editor group
- **WHEN** a plugin appends a token with the StatusLine id
- **THEN** the token is ignored

#### Scenario: A negative state
- **WHEN** a plugin returns -5 as the end state of a line
- **THEN** the next line is tokenized starting in state 0

### Requirement: A plugin resolves highlight group names through the host
`syntax_group(name)` SHALL answer the id of a syntax group or a file-icon group by its name, as a successful response whose number is the id, and fail with `No highlight group named <name>` for any other name, the UI groups included.

#### Scenario: Resolving a group
- **WHEN** a plugin asks for `String` while activating
- **THEN** the response succeeds and its number is the String group's id

#### Scenario: Resolving a file-icon group
- **WHEN** a plugin asks for `DevIconRb`
- **THEN** the response succeeds and its number is the DevIconRb group's id

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

### Requirement: A rename or delete request never goes through a link that leaves the root
The host SHALL refuse a rename or delete request with `Outside the tree root: path` and no change on disk when the directory holding the entry, with every symbolic link resolved, is neither the root with its links resolved nor inside it. A link that resolves inside the root, a root that is itself a link, and a link entry itself, which is renamed or removed and never followed, SHALL still work.

#### Scenario: Rename below a link leading outside
- **WHEN** "/w/out" is a symbolic link to "/elsewhere", which holds "x.rb", and a plugin renames "/w/out/x.rb" to "y.rb" under the root "/w"
- **THEN** the response is failed with "Outside the tree root: out/x.rb" and "/elsewhere/x.rb" still exists

#### Scenario: Delete below a link leading outside
- **WHEN** "/w/out" is a symbolic link to "/elsewhere", which holds "x.rb", and a plugin deletes "/w/out/x.rb" under the root "/w"
- **THEN** the response is failed with "Outside the tree root: out/x.rb" and "/elsewhere/x.rb" still exists

#### Scenario: Rename and delete below a link staying inside
- **WHEN** "/w/alias" is a symbolic link to "/w/lib", and a plugin renames "/w/alias/x.rb" to "y.rb" and then deletes "/w/alias/y.rb" under the root "/w"
- **THEN** both responses succeeded

#### Scenario: Linked root
- **WHEN** the root "/r" is itself a symbolic link to "/real" and a plugin renames "/r/a.rb" to "b.rb" and deletes "/r/b.rb"
- **THEN** both responses succeeded

#### Scenario: The link itself
- **WHEN** "/w/out" is a symbolic link to "/elsewhere" and a plugin renames it to "away" under the root "/w"
- **THEN** the response succeeded and "/elsewhere" and its entries are unchanged

### Requirement: A plugin's scratch buffer takes the plugin's filetype
A scratch buffer opened by a plugin whose manifest declares a filetype equal to the plugin's name SHALL have that syntax, so the plugin tokenizes its own scratch lines; any other scratch buffer SHALL have none.

#### Scenario: The explorer tokenizes its tree
- **WHEN** the explorer, which declares the filetype `explorer`, opens its tree
- **THEN** the tree buffer's syntax is `explorer`

#### Scenario: A plugin without its own filetype
- **WHEN** a plugin that declares no filetype opens a scratch buffer
- **THEN** `:set syntax?` in it shows an empty syntax

### Requirement: A plugin sets its status bar segment with a priority
A plugin SHALL set its own status bar segment with a text and a priority from 0 to 99 through `set_segment`; an empty text SHALL remove the segment, a priority outside 0 to 99 SHALL fail with "priority must be 0 to 99" and change nothing, and `set_status` SHALL set the segment at priority 10. The segments SHALL be shown in the order the plugins first set them and dropped by their priorities when the bar is narrow, and a disabled plugin's segment SHALL be removed.

#### Scenario: A segment with a priority
- **WHEN** a test plugin sets the segment "probe" with priority 95
- **THEN** the bar shows " probe " before the encoding and keeps it after the percent and the position have been dropped for width

#### Scenario: An out-of-range priority
- **WHEN** a test plugin sets a segment with priority 100
- **THEN** the response fails with "priority must be 0 to 99" and the bar shows no segment of that plugin

#### Scenario: set_status keeps working
- **WHEN** the hello plugin's greeting sets its status text "hello 1"
- **THEN** the bar shows " hello 1 " at priority 10

### Requirement: A plugin lists the files below a root through the host
The request `list_files(root, ignore)` (API 2.5) SHALL answer the paths, relative to root, of the regular files below it, recursively, each directory's entries in sorted order. A directory it cannot read SHALL be skipped; a root it cannot read SHALL fail the request. The listing SHALL stop at 100,000 files with a message saying so.

#### Scenario: list_files lists the files below the root
- **WHEN** a plugin asks for the files of a root holding `a.rb`, `lib/b.rb`, and `lib/deep/c.rb`
- **THEN** the response lists `a.rb`, `lib/b.rb`, and `lib/deep/c.rb`

#### Scenario: list_files fails for a missing root
- **WHEN** the root does not exist
- **THEN** the response fails

### Requirement: A file listing keeps to its root
`list_files` SHALL never list nor enter an entry whose name is in `ignore`, never enter a symbolic link to a directory, and skip a symbolic link whose target, every link resolved, is not inside root with its links resolved.

#### Scenario: list_files skips ignored names
- **WHEN** the root also holds `.git/HEAD` and the plugin passes `.git` in ignore
- **THEN** no path under `.git` is listed

#### Scenario: list_files skips a link that leaves the root
- **WHEN** the root holds a link to a file outside it and a link to a file inside it
- **THEN** only the link inside is listed

#### Scenario: list_files does not enter a linked directory
- **WHEN** the root holds a link to one of its own directories
- **THEN** that directory's files are listed once, under its own name

### Requirement: A plugin reads the first rows of a file through the host
The request `read_file(path, rows)` (API 2.5) SHALL answer the first `rows` lines of the regular file at path, without their line endings, reading at most 256 KiB; it SHALL fail with the file system's message for a directory, a special file, a missing file, or a longer file, and fail for `rows` below 1 or above 262,144 (above 1000 before API 2.10), so a file within the read limit can be read whole.

#### Scenario: read_file answers the first rows
- **WHEN** a plugin reads two rows of a file of three lines
- **THEN** the response lists the first two lines

#### Scenario: read_file refuses a directory
- **WHEN** a plugin reads a directory
- **THEN** the response fails with `Is a directory`

#### Scenario: read_file answers rows past the 1000th
- **WHEN** a plugin reads 2000 rows of a file of 2000 lines
- **THEN** the response lists all 2000 lines, line 1500 the 1500th

#### Scenario: read_file refuses more rows than the read limit holds
- **WHEN** a plugin reads 0 rows or 262,145 rows
- **THEN** the response fails with `rows must be 1 to 262144`

### Requirement: A live prompt reports each change
The request `live_prompt(id, text, initial, bindings)` (API 2.5) SHALL open a prompt as `prompt` does, refused while another prompt is open; after every key that changed its text the plugin SHALL receive `on_prompt_change` with the id and the text. Enter and Escape SHALL end it as they end `prompt`, through `on_input`.

#### Scenario: A live prompt delivers each changed text
- **WHEN** a plugin opens a live prompt and the user types `ab`
- **THEN** the plugin receives `on_prompt_change` with `a`, then with `ab`

#### Scenario: Enter ends a live prompt with an answer
- **WHEN** the user types `x` in a live prompt and presses `<CR>`
- **THEN** the plugin receives `on_input` with `x`, and the mode is normal

### Requirement: A live prompt binds the plugin's keys
The bindings of a live prompt, keymap lines of command-line mode, SHALL be consulted before the command-line keymap while the prompt is open, and a key they bind SHALL run the plugin's action with the prompt still open.

#### Scenario: A live prompt's binding runs the plugin's action
- **WHEN** the live prompt binds `<C-n>` to the plugin's action and the user presses `<C-n>`
- **THEN** the plugin's action runs, and the prompt stays open

### Requirement: A plugin closes its own prompt
The request `close_prompt` (API 2.5) SHALL close the plugin's open prompt without an `on_input` and return the editor to normal mode; it SHALL fail when the plugin holds no open prompt.

#### Scenario: close_prompt closes the plugin's prompt
- **WHEN** a plugin with an open prompt asks to close it
- **THEN** the mode is normal and the plugin receives no `on_input`

#### Scenario: close_prompt without a prompt fails
- **WHEN** a plugin with no open prompt asks to close it
- **THEN** the response fails

### Requirement: A plugin runs a program through the host
The request `run_program(argv)` (API 2.7) SHALL run the program the first word names, looked up on the `PATH`, with the other words as its arguments, without a shell, and answer a copy of its standard output, at most 64 KiB, cut before a character the limit would split. The program SHALL get no input, its error output discarded, and the editor's working directory.

#### Scenario: run_program answers the program's output
- **WHEN** a plugin runs `git symbolic-ref --short -q HEAD` and the program prints "main"
- **THEN** the response succeeds with the text "main" and the process port received the four words as given

#### Scenario: The driver runs a program without a shell
- **WHEN** the process runner captures the words `printf`, `%s`, and `a;b`, and then a program that is not installed
- **THEN** the first answers "a;b", the semicolon reaching printf as text, and the second answers nothing

### Requirement: The host refuses a program it should not run
The request SHALL fail without starting anything for an empty command, an empty word, a word holding a NUL character, or a first word holding a `/`, and SHALL fail when the program cannot start, runs past 2 seconds, when it is stopped, or answers bytes that are not UTF-8. A program that ran past 2 seconds SHALL fail with its name and "ran past 2 seconds", and one that cannot start with "cannot run" and its name, so a plugin can tell a slow program from a missing one.

#### Scenario: run_program refuses a path or an empty command
- **WHEN** a plugin runs an empty command, or `./git status`
- **THEN** the response fails and nothing is started

#### Scenario: run_program fails when the program cannot start
- **WHEN** a plugin runs a program that is not installed
- **THEN** the response fails with "cannot run" and the program's name

#### Scenario: run_program says a program ran past its deadline
- **WHEN** a plugin runs a program that runs past 2 seconds
- **THEN** the response fails with the program's name and "ran past 2 seconds"

### Requirement: The host runs a program only under a trusted root
The request `run_program` SHALL fail without starting anything while the editor's working directory is not a root of `language.trusted_roots` or below one, the same roots under which a language server starts on its own, and before the plugins are activated. The response SHALL say the program runs only under a trusted root.

#### Scenario: run_program outside a trusted root starts nothing
- **WHEN** the working directory is outside every root of `language.trusted_roots` and a plugin runs `git symbolic-ref --short -q HEAD`
- **THEN** the response fails naming `language.trusted_roots` and nothing is started

#### Scenario: run_program before activation starts nothing
- **WHEN** a plugin runs a program before the host activated the plugins
- **THEN** the response fails and nothing is started

### Requirement: The host runs a program with git's lazy fetch off
Every program the request starts SHALL have `GIT_NO_LAZY_FETCH=1` in its environment, besides the editor's own variables, so git never fetches a missing object from a promisor remote for a plugin.

#### Scenario: run_program turns lazy fetching off
- **WHEN** a plugin under a trusted root runs a program
- **THEN** the process port receives the variable `GIT_NO_LAZY_FETCH` set to `1`

#### Scenario: The driver adds the variables to the child environment
- **WHEN** the process runner captures a program with `GIT_NO_LAZY_FETCH` set to `1`
- **THEN** the program sees the variable set to `1`

### Requirement: The host runs a program with every git transport refused
Every program the `run_program` request starts SHALL have `GIT_ALLOW_PROTOCOL` set to the empty string in its environment, beside `GIT_NO_LAZY_FETCH=1`, so a git it runs allows no transport, whatever the repository's configuration says and also with a git older than 2.44, which ignores `GIT_NO_LAZY_FETCH`, and a fetch, lazy or not, reaches no remote and starts no command.

#### Scenario: run_program allows no transport
- **WHEN** a plugin under a trusted root runs a program
- **THEN** the process port receives `GIT_NO_LAZY_FETCH` set to `1` and `GIT_ALLOW_PROTOCOL` set to the empty string

#### Scenario: The driver adds an empty variable to the child environment
- **WHEN** the process runner captures a program with `GIT_ALLOW_PROTOCOL` set to the empty string
- **THEN** the program sees the variable set, and empty

### Requirement: A disabled plugin's floats close
When a plugin is disabled, the host SHALL close every float the plugin opened, in every tab page, and leave the floats of other plugins and of the editor open.

#### Scenario: Disabled with floats in two tab pages
- **WHEN** a test plugin with a float in tab page 1 and a float in tab page 2, beside another plugin's float, raises in an action
- **THEN** neither tab page holds a float of the plugin and the other plugin's float is still open

### Requirement: A plugin activates on its first trigger
The host SHALL read an enabled plugin's manifest at startup, resolving its options and merging its default bindings, without activating it. It SHALL activate the plugin, once, on its first trigger: the first run of an action it declares, from a key bound to it or otherwise; the first ex command it declares; or the first time a buffer of a filetype it declares is highlighted.

#### Scenario: No plugin is active at startup
- **WHEN** the editor starts on a markdown file with the explorer, finder, ruby, and git_signs plugins enabled and draws its first frame
- **THEN** none of them is active, and the explorer, finder, and ruby plugins are still not active after the editor goes idle

#### Scenario: The explorer activates on its key
- **WHEN** the editor has started and the explorer's key is pressed
- **THEN** the explorer is active and its window opens as before

#### Scenario: The explorer activates on its ex command
- **WHEN** the editor has started and ":Explorer" is run
- **THEN** the explorer is active and its window opens

#### Scenario: The finder activates on its key
- **WHEN** the editor has started and the finder's key is pressed
- **THEN** the finder is active and its float opens

#### Scenario: The ruby plugin activates on its first ruby buffer
- **WHEN** the editor starts on a text file and then ":e" opens a ruby file
- **THEN** the ruby plugin is not active before the ruby buffer is drawn and is active, its lines highlighted, after

#### Scenario: A raise in a late activate
- **WHEN** a test plugin raises in its activate and the key bound to its action is pressed, then "x" is pressed
- **THEN** the message row reads "Plugin <name> disabled: <error>", the action did not run, and "x" deletes the character

### Requirement: A plugin with no trigger activates when the editor is first idle
A plugin that declares no action, ex command, or filetype SHALL be activated when the editor is first idle after the first frame is drawn, and never before that frame.

#### Scenario: Git runs only after the first frame
- **WHEN** the editor starts on a file in a repository under a trusted root
- **THEN** no git command has run when the first frame is drawn, and once the editor is idle git_signs is active and the branch segment shows

### Requirement: Events reach only an active plugin
Events SHALL reach a plugin only once it is active; what happened before, the plugin reads in its activate. Only an active plugin SHALL be deactivated when the editor ends.

#### Scenario: Events wait for activation
- **WHEN** a plugin with an action, subscribed to every event, is not yet active and a file is opened, then its action runs
- **THEN** it received no event before its activate, and receives the events of later keys

### Requirement: A plugin refills its float in place
The request `set_float_lines(window, lines, title)` (API 2.11) SHALL replace the lines and title of one of the plugin's floats, window 0 for the current window, with a copy of them, keeping its window id, box, and focus, its cursor and selection anchor back on the first line. Another plugin's float, an unknown id, or a float showing a listed buffer SHALL fail with "No float N".

#### Scenario: Refilled in place
- **WHEN** a plugin opens a bordered float titled "old" showing "first" and "rows", and refills it with "other" titled "new"
- **THEN** the float keeps its window id and box, shows "other" under the title "new", and the screen equals a full repaint

#### Scenario: The current float refilled with 0
- **WHEN** the plugin's float is current, its cursor on its second line, and the plugin refills window 0 with one line
- **THEN** that float shows the line, stays current, and its cursor is on its first line

#### Scenario: Refilled with no lines
- **WHEN** the plugin refills its float with no lines
- **THEN** the float shows one empty line

#### Scenario: Another plugin's float is not refilled
- **WHEN** another plugin refills the float, or the plugin refills an id no float has
- **THEN** the request fails with "No float N" and the float keeps its lines and title

#### Scenario: A float showing a scratch buffer is not refilled
- **WHEN** the plugin's float is switched to one of the plugin's listed scratch buffers and the plugin refills that float
- **THEN** the request fails with "No float N" and the scratch buffer keeps its lines and title

#### Scenario: A plugin written against 2.10 still loads
- **WHEN** a plugin's manifest names API version "2.10" and the host has 2.16
- **THEN** the plugin is accepted, while a manifest naming "2.17" is refused naming both versions

### Requirement: A plugin styles its float
The request `style_float(window, selected, spans)` (API 2.12) SHALL replace the style of one of the plugin's floats, 0 for the current window: `selected` is the row drawn in `PmenuSel`, the others then in `Pmenu`, or -1; `spans` are flat quadruples of row, column, length, and group id, drawn as tokens, `PmenuMatch` on the selected row in `PmenuMatchSel`. A refill SHALL drop the style.

#### Scenario: A row and spans styled
- **WHEN** a plugin opens a float showing three lines and styles it with its second row selected and a `PmenuMatch` span on its first and its second row
- **THEN** the second row is drawn in `PmenuSel`, the other rows in `Pmenu`, the span's cells in `PmenuMatch` on the first row and `PmenuMatchSel` on the second, and the screen equals a full repaint

#### Scenario: A restyle repaints
- **WHEN** the plugin styles the same float again with the same row selected and a `PmenuMatch` span on its third row only, its lines unchanged
- **THEN** the first and second rows show no match cell, the span's cells on the third row are in `PmenuMatch`, and the screen equals a full repaint

#### Scenario: Spans without a selected row
- **WHEN** the plugin styles its float with no selected row, a `PmenuSel` span, and a span in a syntax group
- **THEN** the rows stay in `NormalFloat` and the spans' cells are in `PmenuSel` and the syntax group

#### Scenario: An empty style clears it
- **WHEN** the plugin styles its float with no selected row and no span
- **THEN** every row of the float is drawn in `NormalFloat` again

#### Scenario: A refill drops the style
- **WHEN** the plugin refills a styled float with `set_float_lines`
- **THEN** the float's rows are drawn in `NormalFloat` with no span

#### Scenario: A plugin written against 2.11 still loads
- **WHEN** a plugin's manifest names API version "2.11" and the host has 2.16
- **THEN** the plugin is accepted

### Requirement: A float span admits only the popup menu's four groups beside the token groups
A span's group SHALL be a syntax, file-icon, or markup group, `PmenuSel`, `PmenuMatch`, `PmenuMarkSel`, or `PmenuLabelSel` (the last two from API 2.15); any other id SHALL fail with "No float group N". `syntax_group` SHALL resolve those four names and still refuse every other UI group's name, and a tokenizer's token in any of the four SHALL still be dropped.

#### Scenario: Other UI groups are refused
- **WHEN** the plugin styles its float with a span in `Visual`, `PmenuMatchSel`, `Normal`, `MsgDim`, a negative id, or an id past the last group
- **THEN** each request fails with "No float group N" and the float keeps its previous style

#### Scenario: The popup menu groups resolve
- **WHEN** a plugin asks `syntax_group` for "PmenuSel", "PmenuMatch", "PmenuMarkSel", "PmenuLabelSel", and "Visual"
- **THEN** the first four answer their group ids and "Visual" fails with "No highlight group named Visual"

#### Scenario: The selected row's mark and label groups style a span
- **WHEN** a plugin styles its float with its first row selected, a `PmenuMarkSel` span on its first cell and a `PmenuLabelSel` span on the rest of the row
- **THEN** the request succeeds, the first cell is in `PmenuMarkSel`, the rest of the row's text in `PmenuLabelSel`, and the row's padding in `PmenuSel`

### Requirement: A bad float style is refused
`style_float` SHALL fail with "No float N" where `set_float_lines` does, "No row N" for a selected row or a span row outside the float's lines, "Spans are row, column, length, and group" for a list whose length is not a multiple of four, and "No span at column C length L" for a negative column or a length below one. A refused request SHALL leave the float's style unchanged.

#### Scenario: Bad rows and spans are refused
- **WHEN** the plugin styles its float with a selected row past its lines, a span row past them, five span integers, a negative column, or a length of zero
- **THEN** each request fails with its message and the float keeps its previous style

#### Scenario: Another plugin's float is not styled
- **WHEN** another plugin styles the float, or the plugin styles an id no float has or a float switched to a listed buffer
- **THEN** the request fails with "No float N"

### Requirement: A plugin chooses its float's border style
The request `set_float_border(window, style)` (API 2.13) SHALL give one of the plugin's floats, 0 for the current window, the border style `none`, `single`, `double`, `rounded`, or `solid`, drawn as `option.winborder` draws it with its ASCII form, or `""` for `option.winborder`; the float SHALL then be bordered, `none` drawing no edge and no title. Other floats and a refill SHALL keep their border. An older 2.x manifest SHALL load.

#### Scenario: Each float border style
- **WHEN** a plugin opens a bordered float of 2 rows by 10 columns titled "doc" under the shipped `rounded` border and sets its border to `single`, `double`, `solid`, or `rounded`
- **THEN** its corners and edges are drawn with that style's characters around the title and the text

#### Scenario: A float border style in ASCII
- **WHEN** `option.icons ascii` is set, or `NO_COLOR`, and the plugin sets its float's border to `double` or `single`
- **THEN** its top edge reads `+--- doc ----+`, its sides `|`, and its bottom edge `+` and `-`

#### Scenario: A float border style of none
- **WHEN** the plugin sets its bordered float's border to `none`
- **THEN** the float shows its padding and lines with no edge and no title, and the screen equals a full repaint

#### Scenario: A float opened without a border gets one
- **WHEN** the plugin opens a float without a border and sets its border to `double`
- **THEN** the float is drawn with the double corners and edges

#### Scenario: The empty style follows winborder
- **WHEN** `option.winborder single` is set and the plugin sets its float's border to `double` and then to `""`
- **THEN** the float is drawn with the single corners again, and another float of the plugin stays single throughout

#### Scenario: A restyled border repaints
- **WHEN** the plugin changes its float's border from `rounded` to `double`, its box unchanged
- **THEN** the next frame shows the double corners and equals a full repaint

#### Scenario: A plugin requests a border style
- **WHEN** a test plugin opens a float through its host and sets its border to `double`
- **THEN** the request succeeds and the float takes the double style with a border, while a disabled plugin's request is refused with "Plugin NAME is disabled" and the float keeps its border

#### Scenario: A plugin written against 2.12 still loads
- **WHEN** a plugin's manifest names API version "2.12" and the host has 2.16
- **THEN** the plugin is accepted, its bordered float takes `option.winborder` with an edge, and its unbordered float has no edge

### Requirement: A bad border style request is refused
`set_float_border` SHALL fail with "No float N" for another plugin's float or an id no float has, and with "No border style X: none, single, double, rounded, or solid" for any other name. A refused request SHALL leave the float's border unchanged.

#### Scenario: Bad border requests are refused
- **WHEN** the plugin sets its float's border to `thick`, another plugin sets it to `double`, or the plugin sets the border of an id no float has
- **THEN** each request fails with its message and the float keeps its border

### Requirement: A plugin lists the open buffers
The request `list_buffers()` (API 2.14) SHALL answer the paths of the listed file buffers, in the order `:ls` shows them, each as the buffer holds it; scratch buffers, buffers a jump left unlisted, and unnamed buffers SHALL be left out. A disabled plugin's request SHALL be refused.

#### Scenario: The listed file buffers
- **WHEN** `lib/alpha.rb` and `lib/beta.rb` are open beside an unnamed buffer and a plugin's scratch buffer, and a plugin requests `list_buffers`
- **THEN** the response succeeds with the lines `lib/alpha.rb` and `lib/beta.rb`

#### Scenario: A disabled plugin lists no buffers
- **WHEN** a disabled plugin requests `list_buffers` or `recent_files`
- **THEN** the request fails with "Plugin NAME is disabled"

### Requirement: A plugin reads the recent files
The request `recent_files()` (API 2.14) SHALL answer the paths of the files shown in a window since the editor started, most recent first, each once: a file shown again SHALL move to the top, a file whose buffer was deleted SHALL stay, scratch and unnamed buffers SHALL never enter, and the list SHALL keep at most 100 paths, the oldest leaving first.

#### Scenario: Recent files most recent first
- **WHEN** `a.rb`, `b.rb`, and `c.rb` are opened in that order, then `a.rb` again, and `b.rb` is deleted with `:bd`
- **THEN** `recent_files` answers `a.rb`, `c.rb`, and `b.rb`

#### Scenario: The recent files are bounded
- **WHEN** 101 files are opened one after another
- **THEN** `recent_files` answers 100 paths, the last opened first and the first opened gone

### Requirement: A create never follows a link planted after its checks
A file a plugin or the explorer creates SHALL be made only as a new regular file at the path itself. When a symbolic link appears at the path after the checks found nothing there, the create SHALL fail with a failed response, write nothing through the link, and leave the link's target unchanged.

#### Scenario: A link planted at the target after the checks
- **WHEN** a plugin creates "tree/new.rb" under the root "tree" and a symbolic link to a file outside the tree appears at "tree/new.rb" after the checks passed
- **THEN** the response is failed and the outside file keeps its text

### Requirement: A float's selected row spans are drawn under NO_COLOR
Under `NO_COLOR` a plugin float SHALL still draw its spans in `PmenuMarkSel` and `PmenuLabelSel`, as it draws its selected row's fill, so a selected row keeps its bar and weight, while its spans in every other group (`PmenuSel`, `PmenuMatch`, a syntax, file-icon, or markup group) SHALL stay unpainted, as before.

#### Scenario: Selected row spans under NO_COLOR
- **WHEN** `NO_COLOR` is set and a plugin styles its float with a `PmenuMarkSel` and a `PmenuLabelSel` span on its first row, a `Comment` span on its second, and a `PmenuMatch` span on its third
- **THEN** the first row's span cells are in `PmenuMarkSel` and `PmenuLabelSel` and the second and third rows' cells stay in `NormalFloat`

### Requirement: A plugin shows its prompt's text in its float
A plugin SHALL attach its open prompt to one of its own floats with `float_prompt(window)` (API 2.16): while the float is in the current tab page, the cursor SHALL stand in its first text row after the prompt text and the typed text before the command line's cursor, and the command-line row SHALL stay blank; the plugin fills that row. The request SHALL fail with "No prompt is open" or "No float N" (the current window, another plugin's float, or none). The attachment SHALL end with the prompt.

#### Scenario: The cursor stands in the float
- **WHEN** a test plugin opens a float, opens a live prompt, attaches it with `float_prompt`, and "ab" is typed
- **THEN** the request succeeds, the cursor is in the float's first text row after the prompt text and "ab", and the message row is blank

#### Scenario: A refused attachment
- **WHEN** the plugin attaches with no prompt open, or names the current window or an id no float has
- **THEN** the request fails with "No prompt is open", "No float 0", or "No float N"

#### Scenario: The attachment ends with the prompt
- **WHEN** the prompt closes, or the float closes under the open prompt
- **THEN** the attachment is dropped, and in the second case the prompt shows on the command-line row again
