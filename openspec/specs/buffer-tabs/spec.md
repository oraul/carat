# buffer-tabs Specification

## Purpose
The buffer tabs are the top row that lists the listed file buffers with their icons and modified dots, counts the ones that do not fit, and numbers the tab pages at its right end.

## Requirements

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

### Requirement: Tabs that do not fit are counted at the ends
When the tabs do not fit the row, the row SHALL show a run of whole tabs that includes the current buffer's, preceded by " <N " when N tabs are hidden before it and followed by " N> " when N are hidden after it, both in `TabLine`. The run SHALL start as early as the current tab allows.

#### Scenario: Overflow on both sides
- **WHEN** ten files are listed, the sixth is current, and the row is 40 columns wide
- **THEN** the row starts with " <K " for the K hidden tabs before the run, shows the sixth file's tab selected, and ends its tabs with " M> " for the M hidden after it

### Requirement: Tab-page numbers at the right end
When two or more tab pages exist, the right end of the row SHALL show each tab page's number with a space before and after, in order, the current one bold in `TabLineName` and the others dim in `TabLine`, with no accent fill, and the buffer tabs SHALL use only the columns before them. Under 16 colors and NO_COLOR the current one SHALL be in `TabLineSel` and the others in `Normal`. `gt` SHALL move between the buffer tabs and the tab pages are the numbers at the right, under `option.gt` as before.

#### Scenario: Two tab pages
- **WHEN** two tab pages exist, the first current, in a 40-column frame
- **THEN** row 0 ends with " 1  2 " with " 1 " in `TabLineName` and " 2 " in `TabLine`

### Requirement: gt and gT move between the buffer tabs
With `option.gt buffers`, the shipped default, "gt" SHALL show the buffer of the next buffer tab in the current window, wrapping from the last tab to the first, "gT" that of the previous one, wrapping, "{count}gT" that of the tab count tabs back, and "{count}gt" that of the count-th tab of the row, doing nothing when the row has fewer tabs. The current tab page SHALL stay, whether one or more tab pages exist, and a modified current file buffer SHALL be refused or left hidden as ":bn" does.

#### Scenario: gt shows the next buffer tab, wrapping
- **WHEN** "a.txt" and "b.txt" are listed, "a.txt" is current, and "gt" is typed twice
- **THEN** the window shows "b.txt" after the first and "a.txt" after the second

#### Scenario: gT shows the previous buffer tab, wrapping
- **WHEN** "a.txt" and "b.txt" are listed, "a.txt" is current, and "gT" is typed
- **THEN** the window shows "b.txt"

#### Scenario: Counted gt goes to that buffer tab
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed, "a.txt" is current, and "3gt" is typed, then "5gt", then "2gT"
- **THEN** the window shows "c.txt", still "c.txt", and then "a.txt"

#### Scenario: gt keeps the tab page
- **WHEN** two tab pages exist, the second showing "b.txt" is current, and "gt" is typed
- **THEN** the second tab page is still current and its window shows the buffer of the next tab

#### Scenario: gt refuses a modified buffer
- **WHEN** `option.hidden` is off, "a.txt" and "b.txt" are listed, "a.txt" is current and modified, and "gt" is typed
- **THEN** the message is "E37: No write since last change (add ! to override)" and the window still shows "a.txt"

#### Scenario: gt leaves a modified buffer hidden
- **WHEN** `option.hidden` is on, "a.txt" and "b.txt" are listed, "a.txt" is current and modified, and "gt" is typed
- **THEN** the window shows "b.txt" with no message and "a.txt" stays listed, hidden and modified

### Requirement: Bracket keys move between buffers
"]b" and "[b" SHALL show the next and the previous listed file buffer in the current window, wrapping, a count stepping that many, as ":bn" and ":bp" do; "[B" and "]B" SHALL show the first and the last listed file buffer, as ":bfirst" and ":blast" do. They SHALL act alike with one or more tab pages and under either `option.gt` value.

#### Scenario: Bracket b steps through the buffers
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed, "a.txt" is current, and "]b", "2]b", and "[b" are typed in turn
- **THEN** the window shows "b.txt", "a.txt", and "c.txt" in turn

#### Scenario: Bracket B goes to the first and the last buffer
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed, "b.txt" is current, and "]B" then "[B" are typed
- **THEN** the window shows "c.txt" and then "a.txt"

### Requirement: option.gt takes buffers or tabpages
`option.gt` SHALL take `buffers` or `tabpages`; any other word SHALL be reported as `file:line: unknown gt mode WORD` and keep the earlier value.

#### Scenario: An unknown gt mode is refused and keeps the earlier value
- **WHEN** the configuration holds `option.gt pages`
- **THEN** the report reads `.caratrc:1: unknown gt mode pages` and the option keeps its value

### Requirement: The modified mark takes one cell
A tab's modified mark SHALL take exactly one cell, so a tab is as wide modified as unmodified; a `modified` icon wider than one cell SHALL be replaced by the ASCII set's.

#### Scenario: The modified mark keeps the tab's width
- **WHEN** "a.rb" and "b.txt" are listed and "a.rb" is modified, with the nerd, the unicode, or the ascii icons
- **THEN** the tab of "b.txt" starts at the column it starts at when "a.rb" is unmodified

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

### Requirement: A tab is a name and a mark, with no icon
Each tab SHALL read a space, a space, the last segment of the path or `[No Name]`, a space, the `modified` icon or a space, and a space, in list order, with no file icon, no gem, and no separator glyph. The current tab SHALL be in `TabLineSel`, bold on the editor's background with no accent fill, so the bold and the background carry the selection; the others in `TabLine`. Under 16 colors and NO_COLOR the row SHALL have no fill, the current tab bold and every other name in `Normal`.

#### Scenario: Two tabs, one modified
- **WHEN** "src/a.rb" is modified and "b.txt" is current
- **THEN** row 0 reads "  a.rb ●   b.txt" from column 0, the second tab in the selected group, with no `│` in the row

#### Scenario: The selected tab has no icon and no fill
- **WHEN** "a.rb" is current among two listed files
- **THEN** every cell of its tab is in `TabLineSel`, the other tab is in `TabLine`, and no cell of either is a file icon

#### Scenario: Tabs under every icon set
- **WHEN** "a.txt" is current among "a.txt" and "b.txt", with the unicode, nerd, or ascii icons
- **THEN** row 0 reads "  a.txt     b.txt" from column 0, with no icon, gem, `|`, or `*`

#### Scenario: The tab row at 16 colors and NO_COLOR
- **WHEN** two files are listed and the frame is drawn with 16 colors, and again with NO_COLOR
- **THEN** the selected tab is in `TabLineSel`, the other tab is in `Normal`, and the cells past the tabs are in `Normal`, with no `TabLineFill`
