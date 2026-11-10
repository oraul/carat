## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Each window keeps its own jump list
A window SHALL walk only its own jump list, and a new window, opened by a split, `:new`, `:vnew`, or a new tab page, SHALL start with a copy of the list of the window it was opened from, which the two then change apart.

#### Scenario: A split copies the jump list
- **WHEN** `:e b.txt` left `a.txt`, the window is split, and Ctrl-O is typed in the new window
- **THEN** the new window shows `a.txt`, and the other window still shows `b.txt`

#### Scenario: A window walks only its own list
- **WHEN** a split's new window switched with `:e c.txt`, the focus went back to the other window, and Ctrl-O is typed there
- **THEN** that window walks its own entries, never reaching the position the new window left

#### Scenario: A new tab page copies the jump list
- **WHEN** `:e b.txt` left `a.txt`, `:tabnew` opened a tab page, and Ctrl-O is typed there twice
- **THEN** the new tab page's window walks back to `b.txt` and then `a.txt`

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
