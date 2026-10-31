# plugin-windows Specification

## Purpose
Plugin windows are how a plugin draws a list or a view: a scratch buffer it owns, shown in a side window at the edge of the tab page with the plugin's own key bindings, that the file commands never write and never count as unsaved work.

## Requirements

### Requirement: A plugin opens a scratch buffer in a side window
A plugin SHALL open a scratch buffer, titled and holding the lines it gives, in a new window at the left or the right edge of the current tab page, spanning its full height, with the given width; that window SHALL become current and keep its width when the terminal is resized or the windows are equalized. When the layout cannot give the window its width and every other window its minimum, the request SHALL fail with "E36: Not enough room" and nothing changes.

#### Scenario: Left side window
- **WHEN** a test plugin opens the scratch buffer "list" 30 columns wide on the left of an 80-column editor showing "a.txt"
- **THEN** there are two windows, the left one is current, 30 columns wide, and shows the scratch lines, and the right one shows "a.txt"

#### Scenario: Right side window
- **WHEN** the plugin opens it on the right
- **THEN** the right window is current and 30 columns wide

#### Scenario: Width survives equalize
- **WHEN** the side window is open and `<C-w>=` is pressed
- **THEN** the side window is still 30 columns wide

#### Scenario: No room
- **WHEN** the plugin asks for a 79-column side window in an 80-column editor
- **THEN** the response is failed with "E36: Not enough room" and there is one window

### Requirement: Reopening a shown scratch buffer focuses it
A request to open a scratch buffer whose title the plugin already shows in the current tab page SHALL replace that buffer's lines and make its window current instead of opening another window. When the buffer is shown only in another tab page, the request SHALL open a side window in the current tab page showing that same buffer with the new lines, so both tab pages show one buffer.

#### Scenario: Reopening focuses
- **WHEN** the plugin opens "list" again from the other window with new lines
- **THEN** there are still two windows, the side window is current, and it shows the new lines

#### Scenario: Another tab page
- **WHEN** "list" is shown in tab page 1 and the plugin opens it from tab page 2
- **THEN** tab page 2 has a side window showing "list", the buffer list holds one "list" buffer, and tab page 1 still shows it

### Requirement: The scratch window's keymap wins over the mode's keymap
Keys pressed while the current window shows a scratch buffer SHALL be looked up first in the keymap the plugin gave the buffer and then, when that keymap does not bind them and no prefix of its bindings matches, in the mode's keymap, so the plugin's bindings take precedence and ordinary motions still work.

#### Scenario: Plugin binding fires
- **WHEN** the scratch keymap binds `<CR>` to "plugin.test.pick" in normal mode and `<CR>` is pressed in the side window
- **THEN** the plugin's action runs with the cursor row of the side window

#### Scenario: Fallback to the mode's keymap
- **WHEN** "j" is pressed in the side window with a scratch keymap that does not bind it
- **THEN** the cursor moves down in the side window

#### Scenario: Plugin keymap does not leak
- **WHEN** `<C-w>l` moves to the file window and `<CR>` is pressed there
- **THEN** the plugin's action does not run

### Requirement: A scratch window closes like a window and its buffer is never written
`:q` and `<C-w>q` in the scratch window SHALL close it as they close any window, and the scratch buffer SHALL leave the buffer list. A plugin SHALL close its own scratch window by title, with a failed response when it is not shown or is the last window. `:w` on a scratch buffer SHALL report "E382: Cannot write, 'buftype' option is set", `:wa` SHALL skip it, and `:q` on the last window and `:qa` SHALL not treat it as unsaved work.

#### Scenario: Quit closes the side window
- **WHEN** ":q" is run in the side window
- **THEN** there is one window showing "a.txt" and the buffer list holds only "a.txt"

#### Scenario: Plugin closes its window
- **WHEN** the plugin asks to close "list" while its window is shown
- **THEN** the window is gone and the response succeeded

#### Scenario: Write is refused
- **WHEN** ":w" is run in the side window
- **THEN** the message is "E382: Cannot write, 'buftype' option is set"

#### Scenario: Quit-all ignores scratch text
- **WHEN** the plugin replaced the scratch lines and ":qa" is run with every file buffer clean
- **THEN** the editor quits

### Requirement: A plugin replaces the lines of its scratch buffer
A plugin SHALL replace all lines of a scratch buffer by title, leaving it unmodified and keeping every cursor on it inside the text; the request SHALL fail when the plugin has no scratch buffer of that title.

#### Scenario: Replace lines
- **WHEN** the plugin replaces the lines of "list" with ["x"] while the cursor was on row 5
- **THEN** the side window shows ["x"] with the cursor on row 0 and the status line shows no modified marker

#### Scenario: Unknown title
- **WHEN** the plugin replaces the lines of "nope"
- **THEN** the response is failed

### Requirement: A plugin focuses a window and opens a file in it
A plugin SHALL make the window with a given id current, 0 meaning the current window, and SHALL open a file in that window as ":e" would there; a window of another tab page SHALL make that tab page current, and an id no window has SHALL fail with nothing changed. The file SHALL be opened before the focus moves, so a failed open leaves the current window as it was.

#### Scenario: Open in the file window
- **WHEN** the side window is current and the plugin opens "b.txt" in the window that shows "a.txt"
- **THEN** that window shows "b.txt" and is current

#### Scenario: Focus a missing window
- **WHEN** the plugin focuses window id 99 with two windows
- **THEN** the response is failed with "No window 99" and the current window is unchanged

#### Scenario: A window of another tab page
- **WHEN** the plugin focuses the id of a window of tab page 1 while tab page 2 is current
- **THEN** tab page 1 is current and that window is current in it

#### Scenario: A failed open keeps the focus
- **WHEN** the side window is current and the plugin opens a file that cannot be read in the other window
- **THEN** the response is failed and the side window is still current

### Requirement: Opening a file from a plugin keeps unsaved work
When a plugin opens a file in a window, a modified file buffer the window showed SHALL stay in the buffer list, hidden, rather than being dropped, and opening the file the window already shows SHALL leave its buffer as it is. When the window showed a scratch buffer, the window SHALL lose its fixed width.

#### Scenario: Modified buffer stays hidden
- **WHEN** "a.txt" is modified in window 2 and the plugin opens "b.txt" there
- **THEN** window 2 shows "b.txt" and "a.txt" is still listed and modified

#### Scenario: The same file is left alone
- **WHEN** window 2 shows "b.txt" with unsaved changes and the plugin opens "b.txt" there
- **THEN** window 2 is current and the buffer keeps its changes

#### Scenario: Side window becomes a file window
- **WHEN** the plugin opens "b.txt" in its own side window
- **THEN** that window shows "b.txt" and is no longer fixed-width

### Requirement: A side window shows no line numbers
A window showing a scratch buffer SHALL have no line number column whatever the `number` and `relativenumber` options say, as Neovim's tree plugins set `nonumber`; its sign column SHALL still appear while the buffer has signs.

#### Scenario: No numbers
- **WHEN** the `number` option is on and a plugin opens a side window with the lines ["l0", "l1"]
- **THEN** the side window's rows start with "l0" and "l1" at its first column

### Requirement: Windows have stable ids
Every window SHALL receive an integer id when it is created, unique for as long as the editor runs and never given to another window, also after the window closes. The id SHALL not change when other windows open or close or when the window moves in the layout.

#### Scenario: Id survives a window close
- **WHEN** three windows are open, a plugin records the id of the third, and the first window is closed
- **THEN** focusing the recorded id makes the same window current

#### Scenario: Ids are not reused
- **WHEN** a window is closed and a new window is split off
- **THEN** the new window's id differs from every id given before

### Requirement: A plugin opens a file in a split
A plugin SHALL open a file in a new window split horizontally or vertically from the window with a given id, 0 meaning the current window, as ":split" and ":vsplit" would there, with the path given as it is, never parsed as an ex command line. The new window SHALL become current and its id SHALL be in the response; when there is no room the request SHALL fail with "E36: Not enough room".

#### Scenario: Split with a space in the name
- **WHEN** a test plugin opens "my notes.txt" in a horizontal split of the current window
- **THEN** there are two windows, the current one shows "my notes.txt", and the response carries its id

#### Scenario: Vertical split
- **WHEN** a test plugin opens "b.txt" in a vertical split
- **THEN** the two windows are side by side and the current one shows "b.txt"

### Requirement: A plugin opens a file in a tab page
A plugin SHALL open a file in a new tab page after the current one, as ":tabnew" would, with the path given as it is; the new tab page SHALL become current and the response SHALL carry its window's id.

#### Scenario: Tab page with a bar in the name
- **WHEN** a test plugin opens "a|b.txt" in a tab page
- **THEN** there are two tab pages and the current window shows "a|b.txt"
