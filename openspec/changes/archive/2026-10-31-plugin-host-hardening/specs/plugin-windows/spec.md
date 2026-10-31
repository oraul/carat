## MODIFIED Requirements

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

## ADDED Requirements

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
