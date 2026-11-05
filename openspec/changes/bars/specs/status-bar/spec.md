## ADDED Requirements

### Requirement: One status bar for the tab page
The row above the message row SHALL be one status bar across the full width of the screen, as Neovim's `laststatus=3`, showing the current window's buffer and cursor whichever window is current; no window SHALL have a status line of its own. The bar SHALL be filled in the `StatusLine` group.

#### Scenario: One bar under two windows side by side
- **WHEN** "a.txt" is split vertically in a 6-row, 40-column frame and the left window is current
- **THEN** row 4 is one bar from column 0 to column 39 with no separator column in it, and row 5 is the message row

#### Scenario: The bar follows the current window
- **WHEN** two stacked windows show "a.txt" and "b.txt" and "<C-w>j" moves to the bottom one
- **THEN** the bar names "b.txt" and shows the bottom window's cursor

### Requirement: The segments of the bar and their order
The bar SHALL show, from the left, the mode pill, the file, the git branch, and the diagnostics counts, and at the right end, in order, the plugins' segments, the `lsp` slot, the file type, the encoding, the position, and the percent. Each segment SHALL be its text with one space before and one after, so neighbouring segments are two spaces apart and no separator glyph is drawn.

#### Scenario: A plain buffer in normal mode
- **WHEN** "a.txt", unmodified, with the cursor at (0, 0) and the unicode icons, is shown in a 40-column frame
- **THEN** the bar reads " NORMAL  a.txt" at the left and "utf-8  1:1  All " at the right end

### Requirement: The mode pill names the mode
The mode pill SHALL read `NORMAL`, `INSERT`, `VISUAL`, `V-LINE`, `V-BLOCK`, `REPLACE`, `O-PENDING`, or `COMMAND` for the mode.

#### Scenario: Every mode has its pill
- **WHEN** the bar is drawn in normal, insert, visual, visual line, visual block, replace, operator-pending, and command-line mode
- **THEN** the pill reads NORMAL, INSERT, VISUAL, V-LINE, V-BLOCK, REPLACE, O-PENDING, and COMMAND

### Requirement: The file, its type, and the cursor segments
The file SHALL be the buffer's path, the scratch title, or `[No Name]`, followed by a space and the `modified` icon of the icon set when the buffer is modified. The file type SHALL be the buffer's filetype, absent when it has none, and the encoding `utf-8`. The position SHALL be the cursor as `row:col` with 1-based numbers and the percent `All`, `Top`, `Bot`, or the percentage with `%`.

#### Scenario: A modified Ruby buffer in insert mode
- **WHEN** "a.rb" is modified, the cursor is at (2, 4), the window shows every line, and the mode is insert, with the unicode icons
- **THEN** the bar starts with " INSERT  a.rb ● " and ends with " ruby  utf-8  3:5  All "

### Requirement: The reserved slots stay empty until a service fills them
The git branch, the diagnostics counts, and the `lsp` slot SHALL take no cells while empty and keep their place in the order. A branch SHALL show as the `git` icon, a space, and the name. The diagnostics counts SHALL show each count above zero as its icon (`error`, `warning`, `info`, `hint`), a space, and the number, in that order, each in its own group. The `lsp` slot SHALL show the server's name in the group of its state: starting, ready, or error.

#### Scenario: Empty slots take no room
- **WHEN** no branch, no diagnostics, and no server are set
- **THEN** the bar shows the same cells as a bar without those slots

#### Scenario: Filled slots
- **WHEN** the branch is "main", there are 2 errors and 1 hint, and the server "ruby-lsp" is ready, with the unicode icons and a wide frame
- **THEN** the left part reads " NORMAL  a.txt  ± main  ✖ 2 ◇ 1 " and the right part starts with " ruby-lsp " in the ready group

#### Scenario: The lsp slot keeps its place
- **WHEN** the server "ruby-lsp" is set while a plugin segment "x" is shown
- **THEN** " ruby-lsp " stands after " x " and before the encoding

### Requirement: A narrow bar drops segments by priority
When the segments do not fit the width, whole segments SHALL be dropped, the lowest priority first and, between equal priorities, the later one first, until the rest fit. The priorities SHALL be: mode 100, file 90, position 80, diagnostics 70, `lsp` 60, percent 50, branch 40, file type 30, encoding 20, and a plugin's segment its own, 10 unless it set another. When the mode and the file alone do not fit, the file SHALL be cut at the right edge.

#### Scenario: Widths drop segments one by one
- **WHEN** the bar for "a.rb" at (0, 0) is drawn 40, 30, 25, 22, 17, and 12 columns wide
- **THEN** it keeps every segment at 40; drops the encoding at 30; then the file type at 25; then the percent at 22; then the position at 17; and at 12 shows " NORMAL  a.r", the file cut

#### Scenario: A plugin segment by its priority
- **WHEN** one plugin's segment has priority 95 and another's 10 and the bar is too narrow for both
- **THEN** the segment of priority 10 is dropped first, and the segment of priority 95 stays after the position has gone

### Requirement: The mode pill's color follows the mode
The mode pill SHALL be drawn in `StatusLineModeNormal` in normal and operator-pending mode, `StatusLineModeInsert` in insert mode, `StatusLineModeVisual` in the three visual modes, `StatusLineModeReplace` in replace mode, and `StatusLineModeCommand` in command-line mode.

#### Scenario: A row per mode
- **WHEN** the bar is drawn in each mode
- **THEN** the pill's cells carry the group of that mode

### Requirement: The slots' colors follow their kind and state
The diagnostics counts SHALL be drawn in `StatusLineError`, `StatusLineWarn`, `StatusLineInfo`, and `StatusLineHint`, the `lsp` slot in `StatusLineLspStarting`, `StatusLineLspReady`, or `StatusLineLspError` by its state, and every other segment in `StatusLine`.

#### Scenario: A row per state
- **WHEN** the bar is drawn with the server in each state and with a count of each kind
- **THEN** the slot's cells and each count's cells carry the group of that state or kind
