# leader-keys Specification

## Purpose
The leader groups and the save key of the default configuration: which keys after the leader reach the windows, quitting, files, buffers, and the explorer, and what Ctrl-S does, so a user finds a command by its group's first letter.

## Requirements

### Requirement: Leader w is the window group
With the default configuration, in normal mode, `<leader>ws`, `<leader>wv`, `<leader>wh`, `<leader>wj`, `<leader>wk`, `<leader>wl`, `<leader>wc`, and `<leader>wo` SHALL do what `<C-w>` followed by the same last key does (split, vertical split, the four window moves, close, only), with its count. `<leader>w` alone SHALL write nothing and wait for the rest.

#### Scenario: Split and move
- **WHEN** the default configuration is loaded on "a.txt" in a 24-row terminal and Space, "w", "s" are typed and then Space, "w", "j"
- **THEN** two windows are stacked and the bottom one is current

#### Scenario: Vertical split, close, and only
- **WHEN** Space, "w", "v" are typed, then Space, "w", "c"
- **THEN** one window is left, and after Space, "w", "s", Space, "w", "o" one window is left again

#### Scenario: Leader w no longer writes
- **WHEN** a modified buffer with a path is shown and Space then "w" are typed
- **THEN** the file is not written and the buffer stays modified

### Requirement: Leader q is the quit group
With the default configuration, in normal mode, `<leader>qq` SHALL quit the editor as `:qa` does, refused with the same messages by unsaved work, and `<leader>qw` SHALL write every modified buffer and quit as `:wqa` does. `<leader>q` alone SHALL not quit.

#### Scenario: Quit all
- **WHEN** an unmodified buffer is shown and Space, "q", "q" are typed
- **THEN** the editor quits

#### Scenario: Quit all refused by unsaved work
- **WHEN** the buffer is modified and Space, "q", "q" are typed
- **THEN** the editor does not quit and shows the messages `:qa` shows

#### Scenario: Write all and quit
- **WHEN** the buffer of "a.txt" is modified and Space, "q", "w" are typed
- **THEN** "a.txt" holds the buffer's text and the editor quits

#### Scenario: Leader q no longer quits
- **WHEN** Space then "q" are typed
- **THEN** the editor does not quit

### Requirement: Leader f is the file group
With the default configuration, in normal mode, `<leader>fs` SHALL write the current buffer as `:w` does, with its message, and `<leader>ff` SHALL show `Not implemented: file.find` and change nothing until the finder exists.

#### Scenario: Save
- **WHEN** the buffer of "a.txt" is modified and Space, "f", "s" are typed
- **THEN** "a.txt" holds the buffer's text, the buffer is unmodified, and the written message is shown

#### Scenario: Find file placeholder
- **WHEN** Space, "f", "f" are typed
- **THEN** "Not implemented: file.find" is shown and the buffer, windows, and cursor are unchanged

### Requirement: Leader b is the buffer group
With the default configuration, in normal mode, `<leader>bb` SHALL list the buffers as `:ls` does, `<leader>bn` and `<leader>bp` SHALL show the next and previous listed buffer as `:bn` and `:bp` do, a count going that many buffers, and `<leader>bd` SHALL delete the current buffer as `:bd` does, or with a count the buffer of that number as `:bd N` does, refused with the same messages.

#### Scenario: List
- **WHEN** "a.txt" and "b.txt" are listed and Space, "b", "b" are typed
- **THEN** the same lines `:ls` shows are shown

#### Scenario: Next and previous
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed, "a.txt" is current, and Space, "b", "n" are typed
- **THEN** "b.txt" is shown, and after Space, "b", "p" "a.txt" is shown again

#### Scenario: A count steps several buffers
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed, "a.txt" is current, and "2", Space, "b", "n" are typed
- **THEN** "c.txt" is shown

#### Scenario: Delete
- **WHEN** "a.txt" and "b.txt" are listed, "b.txt" is current and unmodified, and Space, "b", "d" are typed
- **THEN** "b.txt" is no longer listed

#### Scenario: Delete refused by a change
- **WHEN** the current buffer is modified and Space, "b", "d" are typed
- **THEN** the buffer stays listed and the `E89` message of `:bd` is shown

### Requirement: Ctrl-S saves in normal and insert mode
With the default configuration, Ctrl-S SHALL write the current buffer as `:w` does in normal mode and in insert mode; in insert mode the editor SHALL stay in insert mode with the cursor where it was, and text typed after it SHALL make the buffer modified again. On a terminal the editor SHALL receive Ctrl-S as a key, the raw mode it runs in turning flow control off.

#### Scenario: Ctrl-S in normal mode
- **WHEN** the buffer of "a.txt" is modified and Ctrl-S is pressed in normal mode
- **THEN** "a.txt" holds the buffer's text and the written message is shown

#### Scenario: Ctrl-S in insert mode
- **WHEN** "hello" is typed in insert mode and Ctrl-S is pressed
- **THEN** the file holds "hello", the mode is still insert, and the cursor is after "hello"

#### Scenario: Ctrl-S on a real terminal
- **WHEN** the editor binary runs on a pseudo-terminal, "isaved" is typed, and the byte 0x13 is sent
- **THEN** the file on disk holds "saved"

### Requirement: Leader e opens the explorer as before
`<leader>e` SHALL keep toggling the file tree as the explorer plugin binds it.

#### Scenario: Explorer key unchanged
- **WHEN** Space then "e" are typed with the explorer enabled
- **THEN** the file tree opens at the left, focused
