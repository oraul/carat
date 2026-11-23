# status-bar Specification

## Purpose
The status bar is the one row above the message row that shows the mode, the current buffer, the cursor, the plugins' segments, and the slots git and language services fill, dropping segments by priority when the terminal is narrow.

## Requirements

### Requirement: One status bar for the tab page
The row above the message row SHALL be one status bar across the full width of the screen, as Neovim's `laststatus=3`, showing the current window's buffer and cursor whichever window is current; no window SHALL have a status line of its own. The bar SHALL be filled in the `StatusLine` group.

#### Scenario: One bar under two windows side by side
- **WHEN** "a.txt" is split vertically in a 6-row, 40-column frame and the left window is current
- **THEN** row 4 is one bar from column 0 to column 39 with no separator column in it, and row 5 is the message row

#### Scenario: The bar follows the current window
- **WHEN** two stacked windows show "a.txt" and "b.txt" and "<C-w>j" moves to the bottom one
- **THEN** the bar names "b.txt" and shows the bottom window's cursor

### Requirement: The segments of the bar and their order
The bar SHALL show, from the left, the mode pill, the file, the git branch, and the diagnostics counts, and at the right end, in order, the plugins' segments, the `lsp` slot, the file type, the encoding, the position, and the percent. Each segment SHALL be its text with a space on each side, and a segment that starts an independent group, all but the file and the percent, one more cell before it; no separator glyph is drawn.

#### Scenario: A plain buffer in normal mode
- **WHEN** "a.txt", unmodified, with the cursor at (0, 0) and the unicode icons, is shown in a 40-column frame
- **THEN** the bar reads " NORMAL  a.txt" at the left and "utf-8   1:1  All " at the right end

### Requirement: The mode pill names the mode
The mode pill SHALL read `NORMAL`, `INSERT`, `VISUAL`, `V-LINE`, `V-BLOCK`, `REPLACE`, `O-PENDING`, or `COMMAND` for the mode.

#### Scenario: Every mode has its pill
- **WHEN** the bar is drawn in normal, insert, visual, visual line, visual block, replace, operator-pending, and command-line mode
- **THEN** the pill reads NORMAL, INSERT, VISUAL, V-LINE, V-BLOCK, REPLACE, O-PENDING, and COMMAND

### Requirement: The file, its type, and the cursor segments
The file SHALL be the buffer's path, the scratch title, or `[No Name]`, then a space and the `modified` icon when modified; a path's folder, up to its last `/`, in `StatusLineDim` and the rest in `StatusLine`. The file type SHALL be the filetype, absent when none, and the encoding `utf-8`. The position SHALL be `row:col`, 1-based, and the percent `All`, `Top`, `Bot`, or `N%`.

#### Scenario: A modified Ruby buffer in insert mode
- **WHEN** "a.rb" is modified, the cursor is at (2, 4), the window shows every line, and the mode is insert, with the unicode icons
- **THEN** the bar starts with " INSERT  a.rb ● " and ends with "  ruby   utf-8   3:5  All "

#### Scenario: The folder before the file name
- **WHEN** the bar for "src/lib/a.rb" is drawn, and again with `NO_COLOR` set
- **THEN** "src/lib/" is in `StatusLineDim` and "a.rb" in `StatusLine`, while "a.rb", "/", and a scratch title are wholly in `StatusLine`

### Requirement: The reserved slots stay empty until a service fills them
The git branch, the diagnostics counts, and the `lsp` slot SHALL take no cells while empty and keep their place in the order. A branch SHALL show as the `git` icon, a space, and the name. The diagnostics counts SHALL show each count above zero as its icon (`error`, `warning`, `info`, `hint`), a space, and the number, in that order, each in its own group. The `lsp` slot SHALL show the server's name and its state (requirement "The lsp slot names the state").

#### Scenario: Empty slots take no room
- **WHEN** no branch, no diagnostics, and no server are set
- **THEN** the bar shows the same cells as a bar without those slots

#### Scenario: Filled slots
- **WHEN** the branch is "main", there are 2 errors and 1 hint, and the server "ruby-lsp" is ready, with the unicode icons and a wide frame
- **THEN** the left part reads " NORMAL  a.txt  ± main  ✖ 2 ◇ 1 " and the right part starts with " ruby-lsp ● ", the name in `StatusLineDim` and the dot in the ready group

#### Scenario: The lsp slot keeps its place
- **WHEN** the server "ruby-lsp" is set while a plugin segment "x" is shown
- **THEN** " ruby-lsp ● " stands after " x " and before the encoding

### Requirement: A narrow bar drops segments by priority
When the segments do not fit the width, whole segments SHALL be dropped, the lowest priority first and, between equal priorities, the later one first, until the rest fit. The priorities SHALL be: mode 100, file 90, position 80, diagnostics 70, `lsp` 60, percent 50, branch 40, file type 30, encoding 20, and a plugin's segment its own, 10 unless it set another. When the mode and the file alone do not fit, the file SHALL be cut at the right edge.

#### Scenario: Widths drop segments one by one
- **WHEN** the bar for "a.rb" at (0, 0) is drawn 40, 32, 25, 20, 19, and 12 columns wide
- **THEN** it keeps every segment at 40; drops the encoding at 32; then the file type at 25; then the percent at 20; then the position at 19; and at 12 shows " NORMAL  a.r", the file cut

#### Scenario: A plugin segment by its priority
- **WHEN** one plugin's segment has priority 95 and another's 10 and the bar is too narrow for both
- **THEN** the segment of priority 10 is dropped first, and the segment of priority 95 stays after the position has gone

### Requirement: The mode pill's color follows the mode
The mode pill SHALL be drawn in `StatusLineModeNormal` in normal and operator-pending mode, `StatusLineModeInsert` in insert mode, `StatusLineModeVisual` in the three visual modes, `StatusLineModeReplace` in replace mode, and `StatusLineModeCommand` in command-line mode.

#### Scenario: A row per mode
- **WHEN** the bar is drawn in each mode
- **THEN** the pill's cells carry the group of that mode

### Requirement: The slots' colors follow their kind and state
The diagnostics counts SHALL be drawn in `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, and `StatusLineDiagnosticHint`, the status bar's count groups, on the bar's background. The `lsp` slot's name SHALL be drawn in `StatusLineDim` and its dot, with the hint after it, in `StatusLineLspStarting` while starting or indexing, `StatusLineLspReady` when ready, `StatusLineLspError` when crashed, and `StatusLineDim` when stopped or untrusted.

#### Scenario: A row per state
- **WHEN** the bar is drawn with the server in each state and with a count of each kind
- **THEN** the name's cells are in `StatusLineDim`, the dot's cells carry the group of that state, and each count's cells carry the group of its kind

### Requirement: The lsp slot names the state
The `lsp` slot SHALL show the server's name, a space, and one dot, the `modified` icon of the icon set, whatever the state; after a crash it SHALL add a space and "crashed :LspRestart", and in an untrusted directory a space and "untrusted :LspStart". The words "starting", "indexing", and "stopped" and the percent SHALL NOT be drawn; the progress segment shows the percent.

#### Scenario: The slot names the state
- **WHEN** the server "ruby-lsp" is indexing at 42 percent, and again stopped, crashed, and untrusted
- **THEN** the slot reads " ruby-lsp ● " for the first two, " ruby-lsp ● crashed :LspRestart " and " ruby-lsp ● untrusted :LspStart " for the others, and " ruby-lsp * " under `option.icons ascii`

### Requirement: Progress segment

While long work runs, the status bar SHALL show a progress segment before the `lsp` slot, at priority 35: a space, the work's title followed by its message when it has one (cut to 40 bytes), a space, a ten-cell bar, and a space. With a percent the bar SHALL show one done cell per ten percent, done cells `━` in `StatusLineLspReady` and the rest `─` in `StatusLineDim`. The segment SHALL go when the work ends.

#### Scenario: A bar at a percent

- **WHEN** work titled `Indexing` reports 40 percent
- **THEN** the bar reads ` Indexing ━━━━────── ` with four done cells in `StatusLineLspReady`, the six others in `StatusLineDim`, and the title in `StatusLine`

### Requirement: Progress without a percent and plain progress

Without a percent the progress bar SHALL show three done cells that move one cell for each report; with `option.reducedmotion true` such a bar SHALL be left out and only the title shown. With `option.icons ascii`, done cells SHALL be `#` and the rest `-`, the done cells still in `StatusLineLspReady` and the rest in `StatusLineDim`. With `NO_COLOR` set and not empty, done cells SHALL be `#` and the rest `-`, the done cells in `StatusLine` and the rest in `StatusLineDim`.

#### Scenario: Reduced motion leaves out a bar without a percent

- **WHEN** `option.reducedmotion` is true and work titled `Indexing` reports no percent
- **THEN** the segment reads ` Indexing `

#### Scenario: An ascii bar

- **WHEN** `option.icons` is "ascii" and work titled `Indexing` reports 40 percent
- **THEN** the segment reads ` Indexing ####------ ` with four done cells in `StatusLineLspReady` and the rest in `StatusLineDim`

#### Scenario: Plain bar under NO_COLOR

- **WHEN** `NO_COLOR` is set and work titled `Indexing` reports 40 percent
- **THEN** the segment reads ` Indexing ####------ ` with the done cells in `StatusLine` and the rest in `StatusLineDim`

#### Scenario: A narrow bar drops the segment before the file type

- **WHEN** the bar is too narrow for every segment
- **THEN** the progress segment (35) is dropped after the file type (30) and before the branch (40)

### Requirement: The quiet text and the spacing of the bar
The file name, the position, the plugins' segments, and the progress title SHALL be drawn in `StatusLine`, and the file's folder, the git branch, the server's name, the file type, the encoding, and the percent in `StatusLineDim`, the quiet text of the bar. The pill and the file SHALL be two cells apart, the position and the percent two, and every other neighbouring pair of segments three, with the same groups under `NO_COLOR`.

#### Scenario: The spacing between the groups
- **WHEN** "a.rb", unmodified, with the branch "main", two errors, and a stopped server "ruby-lsp" is shown in an 80-column frame
- **THEN** the pill and the file are two cells apart, the file and the branch, the branch and the counts, the server, the file type, the encoding, and the position are three cells apart, and the position and the percent two

#### Scenario: The quiet text
- **WHEN** the bar for "a.rb" with the branch "main" is drawn
- **THEN** the branch, the file type, the encoding, and the percent are in `StatusLineDim` and the file and the position are in `StatusLine`

#### Scenario: The bar's groups and spacing
- **WHEN** the bar for "a.rb" with the branch "main", two errors, and a stopped server is drawn in 80 columns, and again with `NO_COLOR` set
- **THEN** the cells carry, from the left, the pill's group, `StatusLine` for the file, `StatusLineDim` for the branch, the error count group, `StatusLineDim` for the server, the file type, and the encoding, `StatusLine` for the position, the gaps, and the fill, and `StatusLineDim` for the percent, with the same cells both times
