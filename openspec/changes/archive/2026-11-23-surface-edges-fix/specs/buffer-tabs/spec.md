## MODIFIED Requirements

### Requirement: Buffer tabs take the top row from two buffers or two tab pages
Under `option.showtabline` 2, row 0 SHALL always be the buffer tabs row; under 1, when two or more file buffers are listed or two or more tab pages exist, and not otherwise; under 0, never. When the row shows the windows SHALL be laid out from row 1, otherwise from row 0. Scratch buffers, such as the file tree, SHALL get no tab. The row SHALL be filled in `TabLineFill`.

#### Scenario: A second file shows the row
- **WHEN** "a.txt" is shown under `option.showtabline 1` and ":e b.txt" is run
- **THEN** row 0 is the buffer tabs row and the first text row of the window is row 1

#### Scenario: One file has no row
- **WHEN** only "a.txt" is listed in one tab page under `option.showtabline 1`
- **THEN** row 0 is the first text row

#### Scenario: One file has the row under 2
- **WHEN** only "a.txt" is listed in one tab page under `option.showtabline 2`
- **THEN** row 0 reads "  • a.txt" from column 0 (from the editor's first column beside a left sidebar) and the first text row of the window is row 1

#### Scenario: The open file's modified mark follows its name under 2
- **WHEN** only "a.txt", modified, is listed under `option.showtabline 2`
- **THEN** row 0 reads "  • a.txt ●" from column 0

#### Scenario: Never hides the row
- **WHEN** two files are listed under `option.showtabline 0`
- **THEN** row 0 is the first text row of the window

#### Scenario: Always shows the row with no file
- **WHEN** no file is listed under `option.showtabline 2`
- **THEN** row 0 is the buffer tabs row and the first text row of the window is row 1

### Requirement: A tab per listed file buffer
Each tab SHALL read a space, a space, the file's icon, a space, the last segment of the path or `[No Name]`, a space, the `modified` icon or a space, and a space, in list order, and draw no gem and no separator glyph. The current tab SHALL be in `TabLineSel`, its leading space and icon included, so the accent background and the bold carry the selection; the others in `TabLine`.

#### Scenario: Two tabs, one modified
- **WHEN** "src/a.rb" is modified and "b.txt" is current, with the unicode icons
- **THEN** row 0 reads "  ◈ a.rb ●   • b.txt" from column 0, the second tab in the selected group, with no `│` in the row

#### Scenario: The selected tab's icon is in the selected group
- **WHEN** "a.rb" is current among two listed files
- **THEN** every cell of its tab, the leading space and the icon included, is in `TabLineSel`, and the other tab is in `TabLine`

#### Scenario: The ascii icons give the ascii gem and separator
- **WHEN** "a.txt" is current among "a.txt" and "b.txt", with the ascii icons
- **THEN** row 0 reads "  . a.txt     . b.txt" from column 0, with no gem, no `|`, and no `*`

## ADDED Requirements

### Requirement: The tabs start at the editor's first column
With a left sidebar shown, the buffer tabs row SHALL leave the cells before the editor's first column, the sidebar's column, width, and one more, to the sidebar's head, fill and write its tabs and its counts from that column, and put the tab-page numbers no further left than it; with no left sidebar it SHALL start at column 0.

#### Scenario: The row starts at the editor's first column
- **WHEN** the tabs row is painted from column 14 of a 40-column row, and with the start past the width
- **THEN** the cells before column 14 are left alone, the first tab starts at column 14, the overflow counts, the run, and the tab-page numbers use only the columns from it, and a start past the width paints no tab

#### Scenario: The tab row beside a sidebar
- **WHEN** a 30-column sidebar and two tabs are shown in an 80-column frame, at 24 bits, at 16 colors, and under `NO_COLOR`
- **THEN** row 0 holds no `│`, its first tab starts at column 31, the editor's first column, and the sidebar's rows hold no `~`

### Requirement: The sidebar's head reads the project and branch
The left sidebar's head SHALL read a space, the project (the last segment of the working directory) in `Normal`, a dot in `NonText` (a hyphen under `option.icons ascii`), and the git branch in `MsgDim` when there is one, on the sidebar's layer and cut at the sidebar's edge. It SHALL stand on the tab row over the sidebar and the column after it, and on the sidebar's first row when no tab row shows.

#### Scenario: The sidebar's head reads the project and branch
- **WHEN** the working directory is "/work/carat" and the branch "main", in the unicode and the ascii icon sets, with no branch, at the root, with no directory, and in a head cut at its edge
- **THEN** the head reads " carat · main" (" carat - main" in ascii), " carat" with no branch, " / · main" at the root, " main" with no directory, and " carat ·" when cut after the dot, the project in `Normal`, the dot in `NonText`, and the branch in `MsgDim`, all on the sidebar layer
