# Spec Delta

## Purpose

Windows let the user look at several buffers, or several places of one buffer, at once: each tab page holds a layout of windows split horizontally and vertically, every window has its own buffer, cursor, and scroll position, and the Ctrl-W commands and their ex forms split, close, and move between them.

## ADDED Requirements

### Requirement: Split opens a window above showing the same buffer
`<C-w>s`, `:sp`, and `:split` SHALL split the current window horizontally: the new window appears above the current one, shows the same buffer with the same cursor and scroll position, and becomes the current window. The new window SHALL get half of the current window's text rows rounded down and the current window SHALL keep the rest minus its status line.

#### Scenario: Split a single window
- **WHEN** the editor shows "a.txt" in one window of a 24-row terminal and `<C-w>s` is pressed
- **THEN** there are two windows, both showing "a.txt", the top one is current with 11 text rows and the bottom one has 10

#### Scenario: Ex forms
- **WHEN** ":sp" or ":split" is run
- **THEN** the window is split as `<C-w>s` does

#### Scenario: Split with a count
- **WHEN** the editor shows one window with 22 text rows and "5<C-w>s" is typed
- **THEN** the new window has 5 text rows and the current window keeps 16

#### Scenario: Edits are shared
- **WHEN** a window is split and "x" is pressed
- **THEN** both windows show the line with the character removed and both status lines carry the modified marker

### Requirement: Vertical split opens a window to the left showing the same buffer
`<C-w>v`, `:vs`, and `:vsplit` SHALL split the current window vertically: the new window appears to the left, shows the same buffer with the same cursor and scroll position, and becomes the current window. The new window SHALL get half of the current window's columns rounded down and the current window SHALL keep the rest minus the separator column.

#### Scenario: Vertical split of a single window
- **WHEN** the editor shows "a.txt" in one window 80 columns wide and `<C-w>v` is pressed
- **THEN** there are two windows side by side, the left one is current and 40 columns wide, and the right one is 39 columns wide

#### Scenario: Ex forms
- **WHEN** ":vs" or ":vsplit" is run
- **THEN** the window is split as `<C-w>v` does

#### Scenario: Vertical split with a count
- **WHEN** one window 80 columns wide is shown and "30<C-w>v" is typed
- **THEN** the new window is 30 columns wide and the current window keeps 49

### Requirement: Split commands take a file to show in the new window
":sp file", ":split file", ":vs file", and ":vsplit file" SHALL split as without an argument and then show the file in the new window, opening it as ":e file" does; ":new" and ":vne[w]" SHALL split and show a new empty buffer with no name. The window that was split SHALL keep showing its buffer.

#### Scenario: Split with a file
- **WHEN** ":sp b.txt" is run while "a.txt" is shown and "b.txt" holds "zz"
- **THEN** the top window is current and shows ["zz"] for "b.txt", the bottom window still shows "a.txt", and the message is the opened message for "b.txt"

#### Scenario: New empty window
- **WHEN** ":new" is run
- **THEN** the top window is current, its buffer has no name and one empty line, and the bottom window still shows the previous buffer

#### Scenario: Vertical new empty window
- **WHEN** ":vnew" or ":vne" is run
- **THEN** the left window is current and shows an unnamed empty buffer

### Requirement: A split that does not fit reports E36
A horizontal split SHALL fail with "E36: Not enough room" when the current window has fewer than three text rows, and a vertical split SHALL fail with the same message when the current window cannot give both windows one text column plus the number column and leave one column for the separator. Nothing SHALL change on failure.

#### Scenario: Not enough rows
- **WHEN** a window with two text rows is split with `<C-w>s`
- **THEN** the message is "E36: Not enough room" and there is still one window

#### Scenario: Not enough columns
- **WHEN** a window 9 columns wide with the number column shown is split with `<C-w>v`
- **THEN** the message is "E36: Not enough room" and there is still one window

### Requirement: Moving to the neighbour window
`<C-w>h`, `<C-w>j`, `<C-w>k`, and `<C-w>l` SHALL make the window to the left, below, above, or to the right of the current one the current window, choosing the neighbour that overlaps the cursor's screen row or column, and SHALL do nothing when there is none. A count SHALL repeat the move, stopping at the edge.

#### Scenario: Down and up
- **WHEN** a window is split with `<C-w>s` and `<C-w>j` is pressed
- **THEN** the bottom window is current, and after `<C-w>k` the top window is current again

#### Scenario: Right and left
- **WHEN** a window is split with `<C-w>v` and `<C-w>l` is pressed
- **THEN** the right window is current, and after `<C-w>h` the left window is current again

#### Scenario: No neighbour
- **WHEN** a window is split with `<C-w>s` and `<C-w>k` is pressed in the top window
- **THEN** the top window stays current

#### Scenario: Count stops at the edge
- **WHEN** three windows are stacked, the top one is current, and "5<C-w>j" is typed
- **THEN** the bottom window is current

### Requirement: Cycling through the windows
`<C-w>w` SHALL make the next window in layout order current, wrapping from the last to the first, and `<C-w>W` the previous one, wrapping from the first to the last. Layout order SHALL be top to bottom and left to right. With a count both SHALL go to the window with that number, or to the last window when the count is larger.

#### Scenario: Next and previous wrap
- **WHEN** two windows are stacked, the top one is current, and `<C-w>w` is pressed twice
- **THEN** the bottom window is current after the first press and the top one after the second

#### Scenario: Previous from the first
- **WHEN** two windows are stacked, the top one is current, and `<C-w>W` is pressed
- **THEN** the bottom window is current

#### Scenario: Numbered window
- **WHEN** three windows are stacked and "3<C-w>w" is typed
- **THEN** the bottom window is current, and "9<C-w>W" keeps it current

### Requirement: Returning to the previously used window
`<C-w>p` SHALL make the window that was current before the last window change current again, and SHALL do nothing when that window no longer exists or none was used.

#### Scenario: Back and forth
- **WHEN** a window is split, `<C-w>j` moves to the bottom window, and `<C-w>p` is pressed
- **THEN** the top window is current, and after `<C-w>p` again the bottom window is current

#### Scenario: Previous window was closed
- **WHEN** a window is split, `<C-w>j` moves to the bottom window, `<C-w>o` closes the top one, and `<C-w>p` is pressed
- **THEN** the remaining window stays current

### Requirement: Closing a window
`<C-w>c`, `:clo`, and `:close` SHALL close the current window and give its space to the window after it in its split, or to the one before it when it was last, which becomes the current window. Closing the last window of a tab page SHALL close that tab page. The last window of the last tab page SHALL NOT be closed: the message SHALL be "E444: Cannot close last window". With a count, `<C-w>c` SHALL close the window with that number.

#### Scenario: Close the top window
- **WHEN** a window is split and `<C-w>c` is pressed
- **THEN** one window remains with the full height and it is current

#### Scenario: Ex forms
- **WHEN** ":close" or ":clo" is run with two windows
- **THEN** the current window is closed

#### Scenario: Last window
- **WHEN** `<C-w>c` is pressed with one window and one tab page
- **THEN** the message is "E444: Cannot close last window" and the window stays

#### Scenario: Close a numbered window
- **WHEN** three windows are stacked, the top one is current, and "3<C-w>c" is typed
- **THEN** two windows remain and the top one is current

### Requirement: Closing a window keeps a modified buffer hidden
When the window closed was the last one showing a modified buffer, the buffer SHALL stay in the buffer list, hidden, so that ":qa" refuses with E37 and ":wa" writes it; a buffer that is unmodified when its last window closes SHALL leave the list.

#### Scenario: Hidden modified buffer blocks quit-all
- **WHEN** ":sp b.txt" is run, "x" is pressed in the new window, `<C-w>c` closes it, and ":qa" is run
- **THEN** the editor stays and the message is "E37: No write since last change (add ! to override)"

#### Scenario: Write-all writes the hidden buffer
- **WHEN** after that ":wa" is run
- **THEN** "b.txt" holds the edited text and ":qa" then ends the editor

#### Scenario: Hidden buffer comes back
- **WHEN** after hiding the modified "b.txt" ":e b.txt" is run
- **THEN** the window shows the edited lines and the buffer is still modified

### Requirement: Closing every other window
`<C-w>o`, `:on`, and `:only` SHALL close every window of the tab page except the current one, which takes the whole area; with one window the message SHALL be "Already only one window".

#### Scenario: Only
- **WHEN** a window is split twice and `<C-w>o` is pressed
- **THEN** one window remains, showing the buffer the current window showed

#### Scenario: Already only one
- **WHEN** ":only" is run with one window
- **THEN** the message is "Already only one window"

### Requirement: Equalizing window sizes
`<C-w>=` SHALL make the windows of every split the same size, the first windows taking any remainder, except that fixed-width windows keep their width and the other windows of their split share the rest.

#### Scenario: Equalize after a count split
- **WHEN** one window with 22 text rows is split with "5<C-w>s" and `<C-w>=` is pressed
- **THEN** the top window has 11 text rows and the bottom one 10

#### Scenario: Fixed width is kept
- **WHEN** a window 80 columns wide is split with "20<C-w>v", the new window is marked fixed-width, and `<C-w>=` is pressed
- **THEN** the left window is still 20 columns wide and the right one 59

### Requirement: Resizing the terminal keeps the layout
When the terminal size changes, every split SHALL keep its windows, the last window of a split absorbing the difference down to its minimum size and then the one before it, with fixed-width windows left alone while another window of the split can change.

#### Scenario: Shrinking the terminal
- **WHEN** a window is split with `<C-w>s` in a 24-row terminal and the terminal becomes 20 rows
- **THEN** the top window keeps 11 text rows and the bottom one has 6

#### Scenario: Fixed width survives a resize
- **WHEN** a fixed-width window 20 columns wide is beside another in an 80-column terminal and the terminal becomes 60 columns
- **THEN** the fixed-width window is still 20 columns wide and the other is 39

### Requirement: Quitting a window
`<C-w>q` SHALL do what ":q" does: close the current window when another window exists in any tab page, closing its tab page when it was that tab page's last window, and end the editor as ":q" does otherwise. With a count it SHALL quit the window with that number.

#### Scenario: Quit one of two windows
- **WHEN** a window is split and `<C-w>q` is pressed
- **THEN** one window remains and the editor is still running

#### Scenario: Quit the last window
- **WHEN** `<C-w>q` is pressed with one window and one tab page on an unmodified buffer
- **THEN** the editor ends

### Requirement: Each window keeps its own cursor and scroll position
A motion in the current window SHALL move only that window's cursor, and switching windows SHALL restore the other window's cursor and scroll position.

#### Scenario: Cursors are independent
- **WHEN** a window is split, "j" is pressed, `<C-w>j` moves to the bottom window, and "jj" is pressed
- **THEN** the bottom window's cursor is on row 2 and after `<C-w>k` the cursor is on row 1
