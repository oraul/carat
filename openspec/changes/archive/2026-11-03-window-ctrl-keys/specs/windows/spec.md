# Spec Delta

## ADDED Requirements

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
