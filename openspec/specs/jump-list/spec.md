# jump-list Specification

## Purpose
The positions `gd` leaves, walked back with Ctrl-O and forward with Ctrl-I across buffers.

## Requirements

### Requirement: Ctrl-O and Ctrl-I walk the jump list
The jump list SHALL hold at most 100 positions, a new entry replacing one on the same buffer line. Ctrl-O SHALL go to the older entry and Ctrl-I to the newer one, by the count, across buffers; at the newest end Ctrl-O SHALL first record the current position so Ctrl-I returns to it, unless no older entry exists. Going past either end SHALL change nothing, and an entry whose buffer is gone SHALL be dropped. Ctrl-O and Ctrl-I SHALL do nothing while a float such as the pick list has the focus.

#### Scenario: Ctrl-O returns and Ctrl-I goes forward again
- **WHEN** `gd` jumped and Ctrl-O then Ctrl-I are typed
- **THEN** Ctrl-O shows the position left and Ctrl-I the target again

#### Scenario: Ctrl-O past the oldest entry does nothing
- **WHEN** the jump list is empty and Ctrl-O is typed
- **THEN** the buffer and cursor are unchanged

#### Scenario: Ctrl-O on an empty list leaves it empty
- **WHEN** the jump list is empty and Ctrl-O then Ctrl-I are typed
- **THEN** the list holds no entry and the buffer and cursor are unchanged

#### Scenario: Ctrl-O in the pick list does nothing
- **WHEN** the pick list has the focus and Ctrl-O is typed
- **THEN** the pick list keeps the focus and its rows, and the jump list is unchanged

#### Scenario: The list keeps the last hundred entries
- **WHEN** 105 positions on different lines are pushed
- **THEN** the list holds the last 100, oldest first

#### Scenario: A new entry on the same line replaces the old one
- **WHEN** two positions on the same buffer line are pushed
- **THEN** the list holds one entry for that line, the newest

### Requirement: A modified buffer refuses a walk to another buffer
A modified current file buffer SHALL refuse a Ctrl-O or Ctrl-I that reaches another buffer with E37, and the refused walk SHALL leave the jump list, its entries and its current entry, as it was.

#### Scenario: A refused Ctrl-O leaves the jump list as it was
- **WHEN** `gd` jumped to another file, the buffer was modified, Ctrl-O was refused with E37, and the buffer is written
- **THEN** the next Ctrl-O shows the position `gd` left and Ctrl-I comes back to the start

### Requirement: Ctrl-O and Ctrl-I follow the jump's tab rule
With `option.jumptab replace`, `Ctrl-O` and `Ctrl-I` to a file buffer that has no tab SHALL show it in the tab of the buffer they leave, at the same position, that buffer losing its tab, so going back and forth never changes the number of tabs. A walk to a buffer that has a tab SHALL select it and change no other tab, and a walk to a scratch buffer SHALL change no tab.

#### Scenario: Ctrl-O gives the buffer gd left its tab back
- **WHEN** `gd` went from `a.rb` alone to `/project/b.rb`, then `Ctrl-O` is pressed, then `Ctrl-I`
- **THEN** after `Ctrl-O` one tab remains, `a.rb`'s, with the cursor where `gd` left it, and after `Ctrl-I` one tab remains, `b.rb`'s

#### Scenario: Back and forth keeps the tab's position
- **WHEN** `lib/x.rb` was opened with `:e`, `:bp` went back to `a.rb`, `gd` went to `/project/b.rb`, and `Ctrl-O` is pressed
- **THEN** the tabs are `a.rb` then `x.rb`, the `a.rb` tab selected

#### Scenario: Ctrl-O across a buffer switch gives the tab back
- **WHEN** `gd` went from `a.rb` alone to `/project/b.rb`, `lib/x.rb` was opened with `:e`, and `Ctrl-O` is pressed twice
- **THEN** the first `Ctrl-O` shows `b.rb` and the second `a.rb` in `b.rb`'s tab, `x.rb` keeping its tab

#### Scenario: A walk back to a scratch buffer keeps the file's tab
- **WHEN** a window showing a scratch buffer, which another window also shows, opened `b.txt` with `:e` and `Ctrl-O` is pressed
- **THEN** the scratch buffer shows and `b.txt` keeps its tab

### Requirement: Each window keeps its own jump list
A window SHALL walk only its own jump list, and a new window, opened by a split, `:new`, `:vnew`, or a new tab page, SHALL start with a copy of the list of the window it was opened from, which the two then change apart.

#### Scenario: A split copies the jump list
- **WHEN** `:e b.txt` left `a.txt`, the window is split, and Ctrl-O is typed in the new window
- **THEN** the new window shows `a.txt`, and the other window still shows `b.txt`

#### Scenario: A window walks only its own list
- **WHEN** a split's new window switched with `:e c.txt`, the focus went back to the other window, and Ctrl-O is typed there
- **THEN** that window walks its own entries, never reaching the position the new window left

#### Scenario: A new tab page copies the jump list
- **WHEN** `:e b.txt` left `a.txt`, `:tabnew` opened a tab page, and Ctrl-O is typed there
- **THEN** the new tab page's window shows `a.txt`, the entry it copied

### Requirement: Every buffer switch joins the jump list
Showing another buffer in the window SHALL record the position the window left in its jump list: `:e`, `:b N`, `:bn`, `:bp`, `:bN`, `:bfirst`, `:blast`, the buffer keys, the finder, the explorer, and `gd`. Ctrl-O and Ctrl-I themselves and `:bd`'s replacement SHALL record nothing, and a file opened over the empty startup buffer SHALL record nothing, as that buffer leaves the list.

#### Scenario: Every buffer switch records the position left
- **WHEN** the cursor is on line 3 of `a.txt` and a buffer switch shows another buffer, then Ctrl-O is typed
- **THEN** the window shows `a.txt` with the cursor on line 3, and Ctrl-I shows the buffer switched to

#### Scenario: Ctrl-O walks back through several switches
- **WHEN** `:e b.txt` and then `:e c.txt` were run from `a.txt` and Ctrl-O is typed twice
- **THEN** the first Ctrl-O shows `b.txt` and the second `a.txt`

#### Scenario: A file opened over the startup buffer records nothing
- **WHEN** the editor started with no file, `:e a.txt` is run, and Ctrl-O is typed
- **THEN** the window keeps `a.txt` and the jump list is empty

#### Scenario: Deleting a buffer records nothing
- **WHEN** `:e b.txt` left `a.txt` and `:bd` showed `a.txt` in place of `b.txt`
- **THEN** the window's jump list holds only the entry `:e` recorded

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
