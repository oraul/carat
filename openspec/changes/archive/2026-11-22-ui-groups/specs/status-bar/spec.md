## MODIFIED Requirements

### Requirement: The segments of the bar and their order
The bar SHALL show, from the left, the mode pill, the file, the git branch, and the diagnostics counts, and at the right end, in order, the plugins' segments, the `lsp` slot, the file type, the encoding, the position, and the percent. Each segment SHALL be its text with a space on each side, and a segment that starts an independent group, all but the file and the percent, one more cell before it; no separator glyph is drawn.

#### Scenario: A plain buffer in normal mode
- **WHEN** "a.txt", unmodified, with the cursor at (0, 0) and the unicode icons, is shown in a 40-column frame
- **THEN** the bar reads " NORMAL  a.txt" at the left and "utf-8   1:1  All " at the right end

### Requirement: The file, its type, and the cursor segments
The file SHALL be the buffer's path, the scratch title, or `[No Name]`, followed by a space and the `modified` icon of the icon set when the buffer is modified. The file type SHALL be the buffer's filetype, absent when it has none, and the encoding `utf-8`. The position SHALL be the cursor as `row:col` with 1-based numbers and the percent `All`, `Top`, `Bot`, or the percentage with `%`.

#### Scenario: A modified Ruby buffer in insert mode
- **WHEN** "a.rb" is modified, the cursor is at (2, 4), the window shows every line, and the mode is insert, with the unicode icons
- **THEN** the bar starts with " INSERT  a.rb ● " and ends with "  ruby   utf-8   3:5  All "

### Requirement: A narrow bar drops segments by priority
When the segments do not fit the width, whole segments SHALL be dropped, the lowest priority first and, between equal priorities, the later one first, until the rest fit. The priorities SHALL be: mode 100, file 90, position 80, diagnostics 70, `lsp` 60, percent 50, branch 40, file type 30, encoding 20, and a plugin's segment its own, 10 unless it set another. When the mode and the file alone do not fit, the file SHALL be cut at the right edge.

#### Scenario: Widths drop segments one by one
- **WHEN** the bar for "a.rb" at (0, 0) is drawn 40, 32, 25, 20, 19, and 12 columns wide
- **THEN** it keeps every segment at 40; drops the encoding at 32; then the file type at 25; then the percent at 20; then the position at 19; and at 12 shows " NORMAL  a.r", the file cut

#### Scenario: A plugin segment by its priority
- **WHEN** one plugin's segment has priority 95 and another's 10 and the bar is too narrow for both
- **THEN** the segment of priority 10 is dropped first, and the segment of priority 95 stays after the position has gone

### Requirement: The slots' colors follow their kind and state
The diagnostics counts SHALL be drawn in `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, and `StatusLineDiagnosticHint`, the status bar's count groups, on the bar's background, the `lsp` slot in `StatusLineLspStarting` while starting or indexing, `StatusLineLspReady` when ready, `StatusLineLspError` when crashed, and `StatusLineDim` when stopped or untrusted.

#### Scenario: A row per state
- **WHEN** the bar is drawn with the server in each state and with a count of each kind
- **THEN** the slot's cells and each count's cells carry the group of that state or kind

## ADDED Requirements

### Requirement: The quiet text and the spacing of the bar
The file, the position, the percent, the plugins' segments, and the progress title SHALL be drawn in `StatusLine`, and the git branch, the file type, and the encoding in `StatusLineDim`, the quiet text of the bar. The pill and the file SHALL be two cells apart, the position and the percent two, and every other neighbouring pair of segments three, with the same groups under `NO_COLOR`.

#### Scenario: The spacing between the groups
- **WHEN** "a.rb", unmodified, with the branch "main", two errors, and a stopped server "ruby-lsp" is shown in an 80-column frame
- **THEN** the pill and the file are two cells apart, the file and the branch, the branch and the counts, the server, the file type, the encoding, and the position are three cells apart, and the position and the percent two

#### Scenario: The quiet text
- **WHEN** the bar for "a.rb" with the branch "main" is drawn
- **THEN** the branch, the file type, and the encoding are in `StatusLineDim` and the file, the position, and the percent are in `StatusLine`

#### Scenario: The bar's groups and spacing
- **WHEN** the bar for "a.rb" with the branch "main", two errors, and a stopped server is drawn in 80 columns, and again with `NO_COLOR` set
- **THEN** the cells carry, from the left, the pill's group, `StatusLine` for the file, `StatusLineDim` for the branch, the error count group, `StatusLineDim` for the server, the file type, and the encoding, and `StatusLine` for the position, the percent, the gaps, and the fill, with the same cells both times
