## ADDED Requirements

### Requirement: The jump motions join the jump list
`G`, `gg`, `(`, `)`, `{`, `}`, `H`, `M`, `L`, `%`, `/`, `?`, `n`, `N`, `*`, `#`, `g*`, `g#`, and a range alone such as `:N` SHALL each add the position the cursor left to the window's jump list when they move, in normal mode, in the visual modes, and under an operator. A motion or search that fails SHALL add nothing, and every other motion SHALL add nothing.

#### Scenario: Each jump form records the position left
- **WHEN** the cursor is on line 2 of a file and a jump form moves it, then Ctrl-O is typed
- **THEN** the jump list holds one entry and Ctrl-O returns to line 2

#### Scenario: Ctrl-I comes back after a jump
- **WHEN** `G` moved the cursor from line 2, then Ctrl-O and Ctrl-I are typed
- **THEN** Ctrl-O shows line 2 and Ctrl-I the last line

#### Scenario: A failed jump records nothing
- **WHEN** a search finds no match, or `(` is typed at the start of the buffer
- **THEN** the jump list stays empty

#### Scenario: Other motions record nothing
- **WHEN** `j`, `w`, or `$` moves the cursor
- **THEN** the jump list stays empty

#### Scenario: A jump under an operator records the position left
- **WHEN** `dG` deletes from line 2 to the end
- **THEN** the jump list holds one entry

#### Scenario: A search under an operator records the position left
- **WHEN** `d/foo` or `dn` deletes up to the next `foo`
- **THEN** the jump list holds one entry more

### Requirement: Each window remembers its alternate buffer
A window SHALL remember the buffer it showed before the current one, set by every buffer switch in it except a file opened over the empty startup buffer, and a new window SHALL take its parent's alternate buffer with the jump list.

#### Scenario: A split keeps the alternate buffer
- **WHEN** `:e b.txt` left `a.txt`, the window is split, and Ctrl-^ is typed in the new window
- **THEN** the new window shows `a.txt`

#### Scenario: A new tab page keeps the alternate buffer
- **WHEN** `:e b.txt` left `a.txt`, `:tabnew` opens a tab page, and Ctrl-^ is typed in it
- **THEN** the new tab page's window shows `a.txt`

### Requirement: Ctrl-^ shows the alternate buffer
Ctrl-^, and Ctrl-6, which terminals send as the same key, SHALL show the window's alternate buffer as `:b N` does, recording the position left and making the buffer left the alternate one; with a count it SHALL show the buffer of that number. Without an alternate buffer it SHALL answer `E23: No alternate file`, and a modified current file buffer SHALL refuse it with `E37`.

#### Scenario: Ctrl-^ goes back and forth
- **WHEN** line 3 of `a.txt` was left by `:e b.txt` and Ctrl-^ is typed twice
- **THEN** the first shows `a.txt` on line 3 and the second `b.txt`

#### Scenario: Ctrl-6 is Ctrl-^
- **WHEN** `:e b.txt` left `a.txt` and Ctrl-6 is typed
- **THEN** the window shows `a.txt`

#### Scenario: A count goes to that buffer
- **WHEN** three buffers are listed and `3` Ctrl-^ is typed in buffer 1
- **THEN** the window shows buffer 3

#### Scenario: No alternate buffer
- **WHEN** only one file was opened and Ctrl-^ is typed
- **THEN** the message is `E23: No alternate file` and the buffer stays

#### Scenario: A modified buffer refuses Ctrl-^
- **WHEN** `b.txt` was modified after leaving `a.txt` and Ctrl-^ is typed
- **THEN** the message is `E37` and `b.txt` stays

### Requirement: :e # edits the alternate file
`:e #` SHALL edit the file of the window's alternate buffer as `:e` with its name does, `:e! #` discarding the changes; without an alternate buffer it SHALL answer `E194: No alternate file name to substitute for '#'`, and for one without a name `E499`.

#### Scenario: :e # shows the alternate file
- **WHEN** `:e b.txt` left `a.txt` and `:e #` is typed
- **THEN** the window shows `a.txt` with `:e`'s message

#### Scenario: :e # without an alternate file
- **WHEN** only one file was opened and `:e #` is typed
- **THEN** the message is `E194: No alternate file name to substitute for '#'`

#### Scenario: :e # on an alternate buffer without a name
- **WHEN** the window's alternate buffer is a modified buffer without a name and `:e #` is typed
- **THEN** the message is `E499` and the buffer stays
