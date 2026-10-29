# Spec Delta

## Purpose
Plugin windows are how a plugin draws a list or a view: a scratch buffer it owns, shown in a side window at the edge of the tab page with the plugin's own key bindings, that the file commands never write and never count as unsaved work.

## ADDED Requirements

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
A request to open a scratch buffer whose title the plugin already shows in the current tab page SHALL replace that buffer's lines and make its window current instead of opening another window.

#### Scenario: Reopening focuses
- **WHEN** the plugin opens "list" again from the other window with new lines
- **THEN** there are still two windows, the side window is current, and it shows the new lines

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
A plugin SHALL make window number n of the current tab page current, and SHALL open a file in window n as ":e" would there, the window numbers being the layout order counted from 1 with 0 meaning the current window; a number past the last window SHALL fail.

#### Scenario: Open in the file window
- **WHEN** the side window is window 1 and the plugin opens "b.txt" in window 2
- **THEN** window 2 shows "b.txt" and is current

#### Scenario: Focus a missing window
- **WHEN** the plugin focuses window 9 with two windows
- **THEN** the response is failed and the current window is unchanged
