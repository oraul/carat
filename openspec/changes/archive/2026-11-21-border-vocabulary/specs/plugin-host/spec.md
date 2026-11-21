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
- **WHEN** a plugin's manifest names API version "2.10" and the host has 2.13
- **THEN** the plugin is accepted, while a manifest naming "2.14" is refused naming both versions

### Requirement: A plugin styles its float
The request `style_float(window, selected, spans)` (API 2.12) SHALL replace the style of one of the plugin's floats, 0 for the current window: `selected` is the row drawn in `PmenuSel`, the others then in `Pmenu`, or -1; `spans` are flat quadruples of row, column, length, and group id, drawn as tokens, `PmenuMatch` on the selected row in `PmenuMatchSel`. A refill SHALL drop the style.

#### Scenario: A row and spans styled
- **WHEN** a plugin opens a float showing three lines and styles it with its second row selected and a `PmenuMatch` span on its first and its second row
- **THEN** the second row is drawn in `PmenuSel`, the other rows in `Pmenu`, the span's cells in `PmenuMatch` on the first row and `PmenuMatchSel` on the second, and the screen equals a full repaint

#### Scenario: A restyle repaints
- **WHEN** the plugin styles the same float again with the same row selected and a `PmenuMatch` span on its third row only, its lines unchanged
- **THEN** the first and second rows show no match cell, the span's cells on the third row are in `PmenuMatch`, and the screen equals a full repaint

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
- **WHEN** a plugin's manifest names API version "2.11" and the host has 2.13
- **THEN** the plugin is accepted

## ADDED Requirements

### Requirement: A plugin chooses its float's border style
The request `set_float_border(window, style)` (API 2.13) SHALL give one of the plugin's floats, 0 for the current window, the border style `none`, `single`, `double`, `rounded`, or `solid`, drawn as `option.winborder` draws it with its ASCII form, or `""` for `option.winborder`; the float SHALL then be bordered, `none` drawing no edge and no title. Other floats and a refill SHALL keep their border. An older 2.x manifest SHALL load.

#### Scenario: Each float border style
- **WHEN** a plugin opens a bordered float of 2 rows by 10 columns titled "doc" under the shipped `rounded` border and sets its border to `single`, `double`, `solid`, or `rounded`
- **THEN** its corners and edges are drawn with that style's characters around the title and the text

#### Scenario: A float border style in ASCII
- **WHEN** `option.icons ascii` is set, or `NO_COLOR`, and the plugin sets its float's border to `double` or `single`
- **THEN** its top edge reads `+--- doc ----+`, its sides `|`, and its bottom edge `+` and `-`

#### Scenario: A float border style of none
- **WHEN** the plugin sets its bordered float's border to `none`
- **THEN** the float shows its padding and lines with no edge and no title, and the screen equals a full repaint

#### Scenario: A float opened without a border gets one
- **WHEN** the plugin opens a float without a border and sets its border to `double`
- **THEN** the float is drawn with the double corners and edges

#### Scenario: The empty style follows winborder
- **WHEN** `option.winborder single` is set and the plugin sets its float's border to `double` and then to `""`
- **THEN** the float is drawn with the single corners again, and another float of the plugin stays single throughout

#### Scenario: A restyled border repaints
- **WHEN** the plugin changes its float's border from `rounded` to `double`, its box unchanged
- **THEN** the next frame shows the double corners and equals a full repaint

#### Scenario: A plugin requests a border style
- **WHEN** a test plugin opens a float through its host and sets its border to `double`
- **THEN** the request succeeds and the float takes the double style with a border, while a disabled plugin's request is refused with "Plugin NAME is disabled" and the float keeps its border

#### Scenario: A plugin written against 2.12 still loads
- **WHEN** a plugin's manifest names API version "2.12" and the host has 2.13
- **THEN** the plugin is accepted, its bordered float takes `option.winborder` with an edge, and its unbordered float has no edge

### Requirement: A bad border style request is refused
`set_float_border` SHALL fail with "No float N" for another plugin's float or an id no float has, and with "No border style X: none, single, double, rounded, or solid" for any other name. A refused request SHALL leave the float's border unchanged.

#### Scenario: Bad border requests are refused
- **WHEN** the plugin sets its float's border to `thick`, another plugin sets it to `double`, or the plugin sets the border of an id no float has
- **THEN** each request fails with its message and the float keeps its border
