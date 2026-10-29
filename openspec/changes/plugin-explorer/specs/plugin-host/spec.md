# Spec Delta

## MODIFIED Requirements

### Requirement: The host refuses a newer major API version
The API SHALL have a version in `major.minor` form, 1.1 since the explorer change added requests. A manifest written against a greater major version SHALL be refused with a message naming the plugin, the version it needs, and the version the host has; a manifest with the same major and any minor SHALL be accepted.

#### Scenario: Newer major
- **WHEN** a plugin's manifest names API version "2.0"
- **THEN** the plugin is disabled and the message row shows that the plugin needs API 2.0 and the host has 1.1

#### Scenario: Newer minor
- **WHEN** a plugin's manifest names API version "1.3"
- **THEN** the plugin is accepted

#### Scenario: Older minor
- **WHEN** a plugin's manifest names API version "1.0"
- **THEN** the plugin is accepted

### Requirement: A plugin reads the file system and the icon table through the host
A plugin SHALL list a directory's entries in sorted order and read the size, modification time, directory flag, and symbolic link flag of a path through the host, with a failed response when the port raises; SHALL ask for an icon by name and receive the glyph of the configured set; and SHALL read its own option values as text.

#### Scenario: Directory listing
- **WHEN** a test plugin lists a directory holding "b.txt" and "a.txt"
- **THEN** it receives ["a.txt", "b.txt"]

#### Scenario: Symbolic link
- **WHEN** a test plugin stats a path that is a symbolic link to a directory
- **THEN** the answer has directory true and symlink true

#### Scenario: Icon by name
- **WHEN** the icons option is "ascii" and a plugin asks for the "folder_closed" icon
- **THEN** it receives "+"

#### Scenario: Option as text
- **WHEN** the explorer plugin reads its "width" option with the shipped configuration
- **THEN** it receives "30"

## ADDED Requirements

### Requirement: Built-in plugins are registered from a generated list
The built-in plugins SHALL be listed in `config/plugins.json` in order, and the editor SHALL construct them from a generated registry with one explicit constructor per plugin. The registry SHALL be regenerated with the configuration mirror, and the test suite SHALL fail when it is out of date with `config/plugins.json`.

#### Scenario: The explorer plugin is listed
- **WHEN** the editor starts with the shipped configuration
- **THEN** the `explorer` plugin is registered, enabled, and its actions and ex commands are available, and no `hello` plugin is registered

#### Scenario: Stale registry
- **WHEN** `config/plugins.json` lists a plugin the generated registry does not construct
- **THEN** the config sync test fails naming the registry

### Requirement: A plugin reads the working directory and window numbers
A plugin SHALL read the editor's working directory as an absolute path; SHALL ask for the number of the window of the current tab page that shows its scratch buffer of a title, 0 when none does; and SHALL ask for the editing window, which is the previously used window when it shows a file buffer, otherwise the first window in layout order that does, 0 when none does.

#### Scenario: Working directory
- **WHEN** the editor runs in "/home/ada/proj" and a plugin asks for the working directory
- **THEN** it receives "/home/ada/proj"

#### Scenario: Scratch window number
- **WHEN** a plugin's scratch buffer "list" is shown in window 1 and the plugin asks for the window of "list"
- **THEN** the number is 1, and for a title it does not show the number is 0

#### Scenario: Editing window
- **WHEN** the side window is current and window 2, the previously used one, shows "a.txt"
- **THEN** the editing window is 2

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

## REMOVED Requirements

### Requirement: Compiled plugins are registered from a generated list
**Reason**: Its scenario named the `hello` plugin as the shipped plugin; the `hello` plugin is now a test fixture outside the registry, and the explorer is the shipped plugin.
**Migration**: The same rule is restated as "Built-in plugins are registered from a generated list", with the explorer as the listed plugin.
