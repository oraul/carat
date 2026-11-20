## ADDED Requirements

### Requirement: A plugin refills its float in place
The request `set_float_lines(window, lines, title)` (API 2.11) SHALL replace every line of one of the plugin's floats, window 0 for the current window, with a copy of the lines, and its title with the given title, keeping its window id, box, and focus, its cursor back on the first line. Another plugin's float, or an id no float has, SHALL fail with "No float N". The host's API version SHALL be 2.11; an older 2.x manifest SHALL still load.

#### Scenario: Refilled in place
- **WHEN** a plugin opens a bordered float titled "old" showing "first" and "rows", and refills it with "other" titled "new"
- **THEN** the float keeps its window id and box, shows "other" under the title "new", and the screen equals a full repaint

#### Scenario: The current float refilled with 0
- **WHEN** the plugin's float is current, its cursor on its second line, and the plugin refills window 0 with one line
- **THEN** that float shows the line, stays current, and its cursor is on its first line

#### Scenario: Refilled with no lines
- **WHEN** the plugin refills its float with no lines
- **THEN** the float shows one empty line

#### Scenario: Another plugin's float is not refilled
- **WHEN** another plugin refills the float, or the plugin refills an id no float has
- **THEN** the request fails with "No float N" and the float keeps its lines and title

#### Scenario: A plugin written against 2.10 still loads
- **WHEN** a plugin's manifest names API version "2.10" and the host has 2.11
- **THEN** the plugin is accepted, while a manifest naming "2.12" is refused naming both versions
