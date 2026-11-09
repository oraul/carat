# layout-slots Specification

## Purpose
Slots give every tab page an IDE layout: a left and a right sidebar and a bottom panel at fixed places, sized by configuration, each showing one plugin view at a time under a header that lists the views opened in it, and hidden or shown again by keys.

## Requirements

### Requirement: Each tab page has two sidebar slots and a panel slot
Each tab page SHALL have a left sidebar slot, a right sidebar slot, and a bottom panel slot, each empty until a view opens in it. A view in a sidebar SHALL take a window at that edge of the tab page spanning its full height; a view in the panel SHALL take a window across the bottom of the tab page between the sidebars, above the status bar. A sidebar SHALL keep its width and the panel its height when the windows are equalized.

#### Scenario: Left sidebar
- **WHEN** a test plugin opens its view "list" in the left slot, 30 columns wide, in an 80-column editor showing "a.txt"
- **THEN** there are two windows, the left one is current, 30 columns wide, and shows "list"

#### Scenario: Panel between the sidebars
- **WHEN** a view is open in the left sidebar and another plugin view opens in the panel 6 rows high
- **THEN** the panel window starts at the column after the left sidebar's separator, spans the rest of the width, and has its 6 rows, header and status row included, at the bottom of the tab page

#### Scenario: Panel keeps its height
- **WHEN** the panel is open, the file window is split, and `<C-w>=` is pressed
- **THEN** the panel keeps its height and the two file windows share the rest

### Requirement: A slot shows one view at a time
A slot SHALL show one view at a time in one window: a view opened in a slot that already has a window SHALL be shown in that window, which becomes current, and the view shown before SHALL be let go.

#### Scenario: One window per slot
- **WHEN** two views open in the left slot one after the other
- **THEN** the tab page has one left sidebar window, showing the second view

### Requirement: A slot's header lists its views
Each slot window SHALL show a header row at its top listing, in the order they opened, the titles of the views opened in the slot since its window was placed, the shown view in the selected tab highlight and the others in the tab highlight; the view's text SHALL start on the row below the header.

#### Scenario: Header of one view
- **WHEN** the explorer opens in the left slot
- **THEN** the first row of the left window reads " explorer " in the selected tab highlight and the tree starts on the second row

#### Scenario: Header of two views
- **WHEN** views "list" and then "other" open in the left slot
- **THEN** the header reads " list  other ", "other" in the selected tab highlight

### Requirement: Slot sizes come from the configuration
The options `option.layout.left_width`, `option.layout.right_width`, and `option.layout.panel_height` SHALL take a number from 0 to 500, 0 by default. A positive value SHALL be the size of the slot's window, in columns for a sidebar and rows for the panel, whatever size the view asks for; 0 SHALL keep the size the view asks for. A value outside the range SHALL be reported as `file:line: option.layout.left_width takes a number from 0 to 500` (with the option's name) and the earlier value kept.

#### Scenario: Configured sidebar width
- **WHEN** the configuration sets `option.layout.left_width 24` and the explorer opens
- **THEN** the explorer's window is 24 columns wide

#### Scenario: Out of range
- **WHEN** the configuration sets `option.layout.panel_height 501`
- **THEN** the problem is reported with its file and line and the panel height stays 0

### Requirement: Keys hide and show each slot
The actions `layout.toggle_sidebar`, `layout.toggle_right_sidebar`, and `layout.toggle_panel` SHALL hide the left sidebar, the right sidebar, and the panel of the current tab page when it is shown, the others taking its space, and SHALL show it again at its edge with the size, view, and cursor it had when it is hidden, leaving the focus where it is.

#### Scenario: Hide and show the explorer
- **WHEN** the explorer is open with its cursor on row 3 and `<leader>ls` is pressed twice
- **THEN** after the first press one window shows "a.md" and is current, and after the second the explorer is back at the left, 30 columns wide, its cursor on row 3, and "a.md" is still current

### Requirement: The slot toggles are bound under the leader
The shipped configuration SHALL bind the slot toggles to `<leader>ls`, `<leader>lr`, and `<leader>lp` in normal mode, under a leader group named layout. Hiding the current window SHALL make another window of the tab page current.

#### Scenario: Hiding the current sidebar
- **WHEN** the explorer is open and current and `<leader>ls` is pressed
- **THEN** the window showing "a.md" is current

### Requirement: A toggle with nothing to toggle is refused
A slot toggle on a slot with no view SHALL answer "No view in the left sidebar", "No view in the right sidebar", or "No view in the panel", and hiding the tab page's only window SHALL answer "E444: Cannot close last window", the layout unchanged either way. A view whose plugin opens it while its slot is hidden SHALL show the slot again.

#### Scenario: Empty slot
- **WHEN** no view was opened and `<leader>lp` is pressed
- **THEN** the message is "No view in the panel" and the layout is unchanged

#### Scenario: Plugin reopens a hidden view
- **WHEN** the explorer is hidden with `<leader>ls` and `<leader>e` is pressed
- **THEN** the explorer is shown at the left again and current
