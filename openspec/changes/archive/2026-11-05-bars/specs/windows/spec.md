## MODIFIED Requirements

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
