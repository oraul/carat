## MODIFIED Requirements

### Requirement: A row shows the kind icon, the label, and the detail
Each row SHALL show the icon of the candidate's kind, looked up by the name `kind_<kind>` in the icons option's set, a space, the label, and the detail or type aligned in a column on the right, with no padding of its own beyond the float's one column on each side, the label starting under the typed part; the selected row SHALL be drawn in `PmenuSel` and the others in `Pmenu`. A label or detail wider than its column SHALL be cut at a character boundary.

#### Scenario: A row's cells
- **WHEN** the popup shows "file_name" of kind "variable" with detail "String" with the ascii icons
- **THEN** its row reads "v file_name  String" and carries `PmenuSel`

#### Scenario: The popup pads one column
- **WHEN** the popup shows under a typed word
- **THEN** the screen shows one padding column in `Pmenu` or `PmenuSel` on each side of the rows' text, the icon in the column after the box's left edge, and each label under the typed word
