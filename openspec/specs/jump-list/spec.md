# jump-list Specification

## Purpose
The positions `gd` leaves, walked back with Ctrl-O and forward with Ctrl-I across buffers.

## Requirements

### Requirement: Ctrl-O and Ctrl-I walk the jump list
The jump list SHALL hold the positions `gd` left, at most 100, an entry on the same buffer line as a new one replaced. Ctrl-O SHALL go to the older entry and Ctrl-I to the newer one, by the count, across buffers; at the newest end Ctrl-O SHALL first record the current position so Ctrl-I returns to it. Going past either end SHALL do nothing, and an entry whose buffer is gone SHALL be dropped. While a float, such as the pick list, has the focus, Ctrl-O and Ctrl-I SHALL do nothing.

#### Scenario: Ctrl-O returns and Ctrl-I goes forward again
- **WHEN** `gd` jumped and Ctrl-O then Ctrl-I are typed
- **THEN** Ctrl-O shows the position left and Ctrl-I the target again

#### Scenario: Ctrl-O past the oldest entry does nothing
- **WHEN** the jump list is empty and Ctrl-O is typed
- **THEN** the buffer and cursor are unchanged

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
With `option.jumptab replace`, `Ctrl-O` and `Ctrl-I` to a buffer that has no tab SHALL show it in the tab of the buffer they leave, at the same position, that buffer losing its tab, so going back and forth never changes the number of tabs. A walk to a buffer that has a tab SHALL select it and change no other tab.

#### Scenario: Ctrl-O gives the buffer gd left its tab back
- **WHEN** `gd` went from `a.rb` alone to `/project/b.rb`, then `Ctrl-O` is pressed, then `Ctrl-I`
- **THEN** after `Ctrl-O` one tab remains, `a.rb`'s, with the cursor where `gd` left it, and after `Ctrl-I` one tab remains, `b.rb`'s

#### Scenario: Back and forth keeps the tab's position
- **WHEN** `lib/x.rb` was opened with `:e`, `:bp` went back to `a.rb`, `gd` went to `/project/b.rb`, and `Ctrl-O` is pressed
- **THEN** the tabs are `a.rb` then `x.rb`, the `a.rb` tab selected
