## MODIFIED Requirements

### Requirement: A plugin refills its float in place
The request `set_float_lines(window, lines, title)` (API 2.11) SHALL replace the lines and title of one of the plugin's floats, window 0 for the current window, with a copy of them, keeping its window id, box, and focus, its cursor and selection anchor back on the first line. Another plugin's float, an unknown id, or a float showing a listed buffer SHALL fail with "No float N".

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

#### Scenario: A float showing a scratch buffer is not refilled
- **WHEN** the plugin's float is switched to one of the plugin's listed scratch buffers and the plugin refills that float
- **THEN** the request fails with "No float N" and the scratch buffer keeps its lines and title

#### Scenario: A plugin written against 2.10 still loads
- **WHEN** a plugin's manifest names API version "2.10" and the host has 2.12
- **THEN** the plugin is accepted, while a manifest naming "2.13" is refused naming both versions

## ADDED Requirements

### Requirement: A plugin styles its float
The request `style_float(window, selected, spans)` (API 2.12) SHALL replace the style of one of the plugin's floats, 0 for the current window: `selected` is the row drawn in `PmenuSel`, the others then in `Pmenu`, or -1; `spans` are flat quadruples of row, column, length, and group id, drawn as tokens, `PmenuMatch` on the selected row in `PmenuMatchSel`. A refill SHALL drop the style. The API SHALL be 2.12; an older 2.x manifest SHALL load.

#### Scenario: A row and spans styled
- **WHEN** a plugin opens a float showing three lines and styles it with its second row selected and a `PmenuMatch` span on its first and its second row
- **THEN** the second row is drawn in `PmenuSel`, the other rows in `Pmenu`, the span's cells in `PmenuMatch` on the first row and `PmenuMatchSel` on the second, and the screen equals a full repaint

#### Scenario: A restyle repaints
- **WHEN** the plugin styles the same float again with its third row selected and no span, its lines unchanged
- **THEN** the third row is drawn in `PmenuSel`, no cell in `PmenuMatch`, and the screen equals a full repaint

#### Scenario: Spans without a selected row
- **WHEN** the plugin styles its float with no selected row, a `PmenuSel` span, and a span in a syntax group
- **THEN** the rows stay in `NormalFloat` and the spans' cells are in `PmenuSel` and the syntax group

#### Scenario: An empty style clears it
- **WHEN** the plugin styles its float with no selected row and no span
- **THEN** every row of the float is drawn in `NormalFloat` again

#### Scenario: A refill drops the style
- **WHEN** the plugin refills a styled float with `set_float_lines`
- **THEN** the float's rows are drawn in `NormalFloat` with no span

#### Scenario: A plugin written against 2.11 still loads
- **WHEN** a plugin's manifest names API version "2.11" and the host has 2.12
- **THEN** the plugin is accepted

### Requirement: A float span admits only the popup menu's two groups beside the token groups
A span's group SHALL be a syntax, file-icon, or markup group, `PmenuSel`, or `PmenuMatch`; any other id SHALL fail with "No float group N". `syntax_group` SHALL resolve `PmenuSel` and `PmenuMatch` and still refuse every other UI group's name, and a tokenizer's token in either group SHALL still be dropped.

#### Scenario: Other UI groups are refused
- **WHEN** the plugin styles its float with a span in `Visual`, `PmenuMatchSel`, `Normal`, `MsgDim`, a negative id, or an id past the last group
- **THEN** each request fails with "No float group N" and the float keeps its previous style

#### Scenario: The popup menu groups resolve
- **WHEN** a plugin asks `syntax_group` for "PmenuSel", "PmenuMatch", and "Visual"
- **THEN** the first two answer their group ids and "Visual" fails with "No highlight group named Visual"

### Requirement: A bad float style is refused
`style_float` SHALL fail with "No float N" where `set_float_lines` does, "No row N" for a selected row or a span row outside the float's lines, "Spans are row, column, length, and group" for a list whose length is not a multiple of four, and "No span at column C length L" for a negative column or a length below one. A refused request SHALL leave the float's style unchanged.

#### Scenario: Bad rows and spans are refused
- **WHEN** the plugin styles its float with a selected row past its lines, a span row past them, five span integers, a negative column, or a length of zero
- **THEN** each request fails with its message and the float keeps its previous style

#### Scenario: Another plugin's float is not styled
- **WHEN** another plugin styles the float, or the plugin styles an id no float has or a float switched to a listed buffer
- **THEN** the request fails with "No float N"
