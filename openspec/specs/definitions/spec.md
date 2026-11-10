# definitions Specification

## Purpose
The definition of the symbol under the cursor, asked of the buffer's language server with `gd` to go there or with the peek key to see it in a float, several targets offered in a pick list, its untrusted target paths opened within the file-access rules.

## Requirements

### Requirement: gd jumps to the definition through the language server
In normal mode `gd` SHALL ask the running language server of the current buffer's file type for the definition at the cursor, without waiting: the answer SHALL be used at the next idle moment with no key pressed. One target SHALL be shown in the current window with the cursor on its line and character, and the position left SHALL be added to the jump list.

#### Scenario: gd sends the request at the next idle tick
- **WHEN** a defining server runs and `gd` is typed on a word
- **THEN** nothing is sent until the next idle tick, which sends the document and the cursor position

#### Scenario: One target in the same file moves the cursor
- **WHEN** the answer is one location in the current file
- **THEN** the cursor is on the target's line and character and the jump list holds the position left

#### Scenario: One target in another project file opens it
- **WHEN** the answer is one location in another file under the working directory
- **THEN** that file is the current buffer with the cursor on the target and Ctrl-O returns to the position left

### Requirement: gd reports Neovim's messages when nothing is found
When the buffer has no path or no running server of its file type advertised definitions, `gd` SHALL show `method textDocument/definition is not supported by any of the servers registered for the current buffer` and ask nothing; an answer with no file target SHALL show `No locations found`.

#### Scenario: gd with no defining server is refused
- **WHEN** the server of a Ruby buffer advertised no definition provider and `gd` is typed
- **THEN** the message row reads Neovim's not-supported message and no definition request is sent

#### Scenario: An empty answer shows No locations found
- **WHEN** the server answers null, an empty list, an error, or only non-file targets
- **THEN** the message row reads `No locations found` and nothing moves

#### Scenario: A modified buffer refuses a jump to another file
- **WHEN** the current file buffer is modified and the target is another file
- **THEN** the message row reads E37 and the buffer stays

### Requirement: Definition requests are asynchronous and dropped when stale
At most one definition request SHALL be in flight; a newer ask SHALL cancel it with `$/cancelRequest`, and so SHALL two seconds without an answer. An answer SHALL be used only when the window, buffer, cursor, and normal mode are where it was asked and no newer ask was made since it was sent.

#### Scenario: A new gd cancels the request in flight
- **WHEN** a request is in flight and `gd` is typed again
- **THEN** the next idle tick cancels the first by its id and sends a second, and the first's late answer is dropped

#### Scenario: An answer after the cursor moved is dropped
- **WHEN** the cursor moves after `gd` and the answer then arrives
- **THEN** nothing moves and no float opens

#### Scenario: An unanswered request is cancelled after two seconds
- **WHEN** the server never answers
- **THEN** the request is cancelled after two seconds and nothing waits any more

### Requirement: The peek key shows the definition in a float
`<leader>dd` SHALL ask the same request and show the target's source in a bordered float at the cursor, at most 12 rows from the target line, titled with the path and line, without leaving the buffer; Esc or a cursor move SHALL close it.

#### Scenario: Peek shows the target lines and keeps the cursor
- **WHEN** `<leader>dd` is answered with one location in another file
- **THEN** a float shows that file's lines from the target line, the current buffer and cursor are unchanged, and the jump list is unchanged

#### Scenario: Esc closes the peek float
- **WHEN** the peek float shows and Esc is typed
- **THEN** no float shows

### Requirement: Several targets show a pick list
An answer with several targets SHALL open an entered float listing them as `N path:line`, at most 50; Enter on a row SHALL go to (or peek) that target and close the list; Esc SHALL close it. The list's keys SHALL be the configuration's `keymap.pick <keys> <action>` lines, bound in normal mode of the list's buffer and in no editor mode, the defaults binding `keymap.pick <CR> definition.choose`.

#### Scenario: Several targets list them and Enter picks one
- **WHEN** the answer has two locations and `j` then Enter are typed in the list
- **THEN** the list showed both rows, and the second target is shown with the list closed

#### Scenario: Esc closes the pick list
- **WHEN** the pick list shows and Esc is typed
- **THEN** no float shows and the buffer and cursor are unchanged

#### Scenario: The pick list's keys come from the configuration
- **WHEN** the user's configuration has `keymap.pick <CR> none` and `keymap.pick o definition.choose`, and Enter, then `G` and `o` are typed in the list
- **THEN** Enter leaves the list open, and `o` shows the second target with the list closed

### Requirement: Targets outside the project open read-only
A target SHALL open through the file-open refusals (a directory, a non-regular file, a file over the limit). A target outside the working directory, or whose path leaves it through a link, SHALL open as a read-only view titled with its path, which `:w` refuses.

#### Scenario: A target outside the project opens read-only
- **WHEN** the answer is one location in a file outside the working directory
- **THEN** a scratch view of it titled with its path is current, on the target line, and `:w` is refused

#### Scenario: A target that is not a regular file is refused
- **WHEN** the answer is one location whose path is a directory
- **THEN** the message row reads the directory refusal and the buffer stays
