## ADDED Requirements

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
The request `read_file(path, rows)` (API 2.5) SHALL answer the first `rows` lines of the regular file at path, without their line endings, reading at most 256 KiB; it SHALL fail with the file system's message for a directory, a special file, a missing file, or a longer file, and fail for `rows` below 1 or above 1000.

#### Scenario: read_file answers the first rows
- **WHEN** a plugin reads two rows of a file of three lines
- **THEN** the response lists the first two lines

#### Scenario: read_file refuses a directory
- **WHEN** a plugin reads a directory
- **THEN** the response fails with `Is a directory`

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
