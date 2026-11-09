# windows Specification

## Purpose
Windows let the user look at several buffers, or several places of one buffer, at once: each tab page holds a layout of windows split horizontally and vertically, every window has its own buffer, cursor, and scroll position, and the Ctrl-W commands and their ex forms split, close, and move between them.

## Requirements

### Requirement: Split opens a window above showing the same buffer
`<C-w>s`, `:sp`, and `:split` SHALL split the current window horizontally: the new window appears above the current one, shows the same buffer with the same cursor and scroll position, and becomes the current window. The new window SHALL get half of the current window's text rows rounded down and the current window SHALL keep the rest minus the separator row between them.

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
- **THEN** both windows show the line with the character removed and the status bar carries the modified icon

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

#### Scenario: Neighbour by layout rectangles
- **WHEN** a window is split with `<C-w>v`, the right window is split with `<C-w>s`, and in the left window `<C-w>l` is pressed with the cursor on the first row, or in another editor with the cursor on a row below the upper right window's rectangle
- **THEN** the upper right window is current, or the lower right window, since each is the window whose layout rectangle abuts the left window's and overlaps the cursor's screen row; from either right window `<C-w>h` makes the left window current

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
When the window closed was the last one showing a file buffer, the buffer SHALL stay in the buffer list, hidden, with its changes, so that ":qa" refuses a modified one with E37 and E162 and ":wa" writes it; it SHALL stay listed after the write, and an unmodified one SHALL stay listed too, until ":bd" deletes it. A plugin's scratch buffer SHALL leave the list when its last window closes.

#### Scenario: Hidden modified buffer blocks quit-all
- **WHEN** ":sp b.txt" is run, "x" is pressed in the new window, `<C-w>c` closes it, and ":qa" is run
- **THEN** the editor stays and the message is "E37: No write since last change" and "E162: No write since last change for buffer "b.txt"" on two lines

#### Scenario: Write-all writes the hidden buffer
- **WHEN** after that ":wa" is run
- **THEN** "b.txt" holds the edited text, it is still listed, and ":qa" then ends the editor

#### Scenario: Hidden buffer comes back
- **WHEN** after hiding the modified "b.txt" ":e b.txt" is run
- **THEN** the window shows the edited lines and the buffer is still modified

#### Scenario: A clean buffer stays listed
- **WHEN** ":sp b.txt" is run and `<C-w>c` closes the new window without an edit
- **THEN** "b.txt" is still listed, hidden

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

### Requirement: Plugin side windows do not keep a tab page open
When the current window shows a file and every other window of its tab page shows a plugin's scratch buffer, `<C-w>q` SHALL treat it as the tab page's last window, taking precedence over closing it alone: it SHALL close the tab page with its side windows when other tab pages exist, and otherwise end the editor as ":q" does on the last window.

#### Scenario: Quit beside a side window
- **WHEN** a plugin's side window is open, the file window is current, and `<C-w>q` is pressed on an unmodified buffer
- **THEN** the editor ends

#### Scenario: Quit in the side window
- **WHEN** a plugin's side window is current and `<C-w>q` is pressed
- **THEN** only the side window closes

### Requirement: Window geometry is current after every key
After every key, and after a file is opened, every window of the current tab page SHALL have the rectangle the layout gives it in the current terminal size and SHALL be scrolled to keep its cursor visible, whether or not a frame was drawn, so a window command, a split's size, and the screen motions "H", "M", and "L" use the windows as they are after the previous key.

#### Scenario: Two splits with no frame between them
- **WHEN** the editor shows one window with 22 text rows in a 24-row terminal and `<C-w>s<C-w>s` is typed with no frame drawn between the keys
- **THEN** there are three windows of 5, 5, and 10 text rows, the top one current

#### Scenario: Screen motion after a jump with no frame between
- **WHEN** a window of 8 text rows over forty lines with scrolloff 0 is at the top, "30G" is typed and then "H" with no frame drawn between them
- **THEN** the cursor is on line 23, the top line the window shows after the jump

### Requirement: Window commands wait for their second key
`<C-w>` SHALL wait for the key that completes the window command however long it takes to arrive, so `<C-w>h j k l w W p` typed slowly move focus exactly as typed together.

#### Scenario: A slow second key
- **WHEN** a window is split with `<C-w>v`, `<C-w>` is pressed, more than timeoutlen passes, and "l" is pressed
- **THEN** the right window is current and the cursor has not moved

#### Scenario: A slow second key for the next window
- **WHEN** a window is split with `<C-w>s`, `<C-w>` is pressed, more than timeoutlen passes, and "w" is pressed
- **THEN** the bottom window is current

### Requirement: Moving between the file tree and the file windows
The window commands SHALL treat the file tree's window as any other window: `<C-w>h j k l w W p` SHALL move focus out of the tree into the file windows and back into the tree, also when the second key comes after timeoutlen, and the tree's own keys SHALL not run in place of the window command.

#### Scenario: Out of the tree and back, slowly
- **WHEN** the tree is opened at the left with `<leader>e`, `<C-w>` is pressed, more than timeoutlen passes, "l" is pressed, then `<C-w>`, a wait, and "h"
- **THEN** the file window is current after "l", the tree is current after "h", and no tree entry was opened or collapsed

#### Scenario: Cycling through the tree
- **WHEN** the tree is open beside one file window and focused, and `<C-w>w` is pressed twice
- **THEN** the file window is current after the first press and the tree after the second, and `<C-w>p` returns to the file window

### Requirement: Window commands with Ctrl held on the second key
`<C-w><C-s>`, `<C-w><C-v>`, `<C-w><C-h>`, `<C-w><C-j>`, `<C-w><C-k>`, `<C-w><C-l>`, `<C-w><C-w>`, `<C-w><C-p>`, `<C-w><C-o>`, and `<C-w><C-q>` SHALL do in normal mode exactly what `<C-w>s`, `<C-w>v`, `<C-w>h`, `<C-w>j`, `<C-w>k`, `<C-w>l`, `<C-w>w`, `<C-w>p`, `<C-w>o`, and `<C-w>q` do, a count typed before `<C-w>` included, from a file window and from the explorer tree. `<C-w><C-c>` SHALL change nothing: the `<C-c>` cancels the window command, as in Vim.

#### Scenario: Split and vertical split
- **WHEN** one window with 22 text rows and 80 columns is shown and `<C-w><C-s>` is pressed, or `<C-w><C-v>` in another editor
- **THEN** the windows are as after `<C-w>s`, two stacked with the top one current, or as after `<C-w>v`, two side by side with the left one current

#### Scenario: Split with a count
- **WHEN** "5<C-w><C-s>" is typed in one window with 22 text rows, or "30<C-w><C-v>" in one window 80 columns wide
- **THEN** the new window has 5 text rows, or 30 columns

#### Scenario: Neighbour moves
- **WHEN** a window is split with `<C-w>s` and `<C-w><C-j>` is pressed, then `<C-w><C-k>`; or split with `<C-w>v` and `<C-w><C-l>` is pressed, then `<C-w><C-h>`
- **THEN** the bottom, or right, window is current after the first key and the first window again after the second

#### Scenario: Neighbour move with a count
- **WHEN** a window is split twice with `<C-w>s` and "5<C-w><C-j>" is typed
- **THEN** the bottom window is current, the move having stopped at the edge

#### Scenario: Next window and a window number
- **WHEN** a window is split with `<C-w>s` and `<C-w><C-w>` is pressed twice; or split twice and "3<C-w><C-w>" is typed
- **THEN** the second window is current after the first press and the first after the second, wrapping; with the count the third window is current

#### Scenario: Previous window, only, and quit
- **WHEN** a window is split with `<C-w>s`, `<C-w>j` is pressed, then `<C-w><C-p>`; or split twice and `<C-w><C-o>` is pressed; or split and `<C-w><C-q>` is pressed; or split twice and "3<C-w><C-q>" is typed
- **THEN** the top window is current again; one window is left; one window is left and the editor runs; the third window is closed and two are left

#### Scenario: Quit on the last window
- **WHEN** one window shows an unmodified buffer and `<C-w><C-q>` is pressed
- **THEN** the editor quits, as with `<C-w>q`

#### Scenario: Control-C cancels the window command
- **WHEN** a window is split with `<C-w>s` and `<C-w><C-c>` is pressed, then `j`
- **THEN** there are still two windows, the top one current, and `j` moved the cursor down one line

#### Scenario: Into and out of the explorer tree
- **WHEN** the explorer tree is open and focused and `<C-w><C-l>` is pressed, then `<C-w><C-h>`
- **THEN** the file window is current after the first key with the tree unchanged, and the tree is current again after the second with its cursor where it was

#### Scenario: Cycling and returning through the tree
- **WHEN** the explorer tree is focused and `<C-w><C-w>` is pressed twice; or `<C-w><C-l>` and then `<C-w><C-p>` are pressed
- **THEN** the file window is current after the first press and the tree after the second; `<C-w><C-p>` returns to the tree

#### Scenario: A pause after Control-W in the tree
- **WHEN** the explorer tree is focused, `<C-w>` is pressed, more than timeoutlen passes, and `<C-l>` is pressed
- **THEN** the file window is current, as after `<C-w>l` with a pause
