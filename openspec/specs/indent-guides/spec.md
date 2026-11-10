# indent-guides Specification

## Purpose
Indent guides mark the indentation levels of the text in file windows, so the lines of one block line up visibly and the block holding the cursor stands out.

## Requirements

### Requirement: Guides at each shiftwidth level
With `option.indentguides` on, a file window SHALL draw the guide character in the `IblIndent` group at every display column of a line's leading whitespace that is a multiple of `shiftwidth` (of `tabstop` when `shiftwidth` is 0) and lies before the first non-blank character, tabs counted to the next multiple of `tabstop`, shifted with the window's horizontal scroll. A line with no leading whitespace has no guide.

#### Scenario: Guides at each level
- **WHEN** a line indented by four spaces is shown with `shiftwidth` 2
- **THEN** guides are drawn at the line's display columns 0 and 2 and the text follows unchanged

#### Scenario: Shiftwidth 0 uses tabstop
- **WHEN** a line indented by eight spaces is shown with `shiftwidth` 0 and `tabstop` 4
- **THEN** guides are drawn at display columns 0 and 4

#### Scenario: A tab indent
- **WHEN** a line indented by one tab is shown with `tabstop` 4 and `shiftwidth` 2
- **THEN** guides are drawn at display columns 0 and 2

#### Scenario: Scrolled sideways
- **WHEN** the window is scrolled one column to the right over a line indented by four spaces with `shiftwidth` 2
- **THEN** the guide of display column 2 is drawn at the window's first text column plus 1 and the guide of column 0 is not drawn

### Requirement: Guides cross blank lines
A blank or whitespace-only line SHALL show the guides of the smaller of the indents of the nearest non-blank line above it and the nearest non-blank line below it, none when either side has no such line within 1000 lines.

#### Scenario: A blank line inside a block
- **WHEN** an empty line lies between two lines indented by four spaces, with `shiftwidth` 2
- **THEN** the empty line shows guides at display columns 0 and 2

#### Scenario: A blank line before a dedent
- **WHEN** an empty line lies between a line indented by four spaces and a line indented by two, with `shiftwidth` 2
- **THEN** the empty line shows a guide at display column 0 only

### Requirement: The cursor's block is highlighted
In the current window, the guide at the deepest level below the cursor line's indent (its carried indent when the line is blank) SHALL be drawn in the `IblScope` group on the cursor's row and on every contiguous row above and below it whose indent, or carried indent, is deeper than that level. With the cursor on a line of no indent no guide is highlighted. Moving the cursor into another block SHALL repaint the rows whose highlight changed.

#### Scenario: The cursor in a nested block
- **WHEN** the cursor is on the middle line of three lines indented by four spaces, below a line indented by two and above a line indented by two, with `shiftwidth` 2
- **THEN** the guide at display column 2 is in `IblScope` on the three lines and the guide at column 0 stays in `IblIndent`

#### Scenario: The cursor at the top level
- **WHEN** the cursor is on a line with no indent
- **THEN** every guide is in `IblIndent`

#### Scenario: The cursor moves to another block
- **WHEN** the cursor moves from a block indented by four spaces to a line indented by two
- **THEN** the guide at display column 0 is in `IblScope` over that line's block and the guides at column 2 are in `IblIndent`

#### Scenario: On the cursor line
- **WHEN** `cursorline` is on and the cursor's line has guides
- **THEN** the guides on that row are drawn on the cursor-line layer of their groups

### Requirement: The guides option
`option.indentguides` SHALL take `true` or `false`, off in fresh options and on in the shipped configuration, and a line with another value SHALL be reported as `file:line: option.indentguides takes true or false`, keeping the value before it. With the option off no guide is drawn.

#### Scenario: Off draws none
- **WHEN** `option.indentguides false` is set and an indented line is shown
- **THEN** its leading whitespace is blank

#### Scenario: The shipped configuration turns them on
- **WHEN** the editor starts with the shipped configuration only
- **THEN** `indentguides` is on and the guide character is `┊`

#### Scenario: A value that is not a flag
- **WHEN** a configuration line reads `option.indentguides yes`
- **THEN** the problem `file:line: option.indentguides takes true or false` is reported and the guides keep their earlier setting

### Requirement: The guide character and its ASCII fallback
`option.indentguides.char` SHALL set the guide character to one character one display column wide that is not a control character; any other value SHALL be reported as `file:line: option.indentguides.char takes one character one column wide`, keeping the character before it. With `option.icons ascii` a guide character outside ASCII SHALL be drawn as `|`, and an ASCII one as set.

#### Scenario: Another character
- **WHEN** `option.indentguides.char ▏` is set and an indented line is shown
- **THEN** its guides are `▏`

#### Scenario: A character too wide or too long
- **WHEN** a configuration line sets `option.indentguides.char` to `ab` or to a double-width character
- **THEN** the problem `file:line: option.indentguides.char takes one character one column wide` is reported and the character before it is kept

#### Scenario: The ASCII fallback
- **WHEN** `option.icons ascii` is set with the default guide character
- **THEN** the guides are drawn as `|`

#### Scenario: An ASCII character is kept
- **WHEN** `option.icons ascii` and `option.indentguides.char :` are set
- **THEN** the guides are drawn as `:`

### Requirement: Guides only in file windows
Guides SHALL be drawn only in windows showing a file buffer: a plugin's buffer (the explorer, a pick list), a float, and the start screen SHALL show none.

#### Scenario: A plugin's window
- **WHEN** a window shows an indented buffer that a plugin owns
- **THEN** its leading whitespace is blank

#### Scenario: A float
- **WHEN** a float shows indented lines over a file window
- **THEN** the float's rows show no guide
