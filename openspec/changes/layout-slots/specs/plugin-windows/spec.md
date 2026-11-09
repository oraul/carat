## MODIFIED Requirements

### Requirement: A plugin opens a scratch buffer in a side window
A plugin SHALL open a scratch buffer, titled and holding the given lines, in the tab page's slot its side names: `left` and `right` for the sidebars, spanning the full height with the given width, and `bottom` for the panel with the given height, unless the slot's size option is positive. The window SHALL become current and keep its size when the terminal is resized or the windows are equalized. When the layout has no room for it, the request SHALL fail with "E36: Not enough room" and nothing changes.

#### Scenario: Left side window
- **WHEN** a test plugin opens the scratch buffer "list" 30 columns wide on the left of an 80-column editor showing "a.txt"
- **THEN** there are two windows, the left one is current, 30 columns wide, and shows the scratch lines, and the right one shows "a.txt"

#### Scenario: Right side window
- **WHEN** the plugin opens it on the right
- **THEN** the right window is current and 30 columns wide

#### Scenario: Bottom panel window
- **WHEN** the plugin opens it at the bottom 6 rows high
- **THEN** the bottom window is current, spans the width, and takes 6 rows

#### Scenario: Width survives equalize
- **WHEN** the side window is open and `<C-w>=` is pressed
- **THEN** the side window is still 30 columns wide

#### Scenario: No room
- **WHEN** the plugin asks for a 79-column side window in an 80-column editor
- **THEN** the response is failed with "E36: Not enough room" and there is one window

## ADDED Requirements

### Requirement: A scratch window's side is checked
A request to open a scratch buffer at a side other than `left`, `right`, or `bottom` SHALL fail with "No side NAME: left, right, or bottom" and change nothing.

#### Scenario: Unknown side
- **WHEN** the plugin asks for the side "top"
- **THEN** the response is failed with "No side top: left, right, or bottom"
