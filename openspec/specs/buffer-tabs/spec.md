# buffer-tabs Specification

## Purpose
The buffer tabs are the top row that lists the listed file buffers with their icons and modified dots, counts the ones that do not fit, and numbers the tab pages at its right end.

## Requirements

### Requirement: Buffer tabs take the top row from two buffers or two tab pages
When two or more file buffers are listed or two or more tab pages exist, row 0 SHALL be the buffer tabs row and the windows SHALL be laid out from row 1; otherwise there SHALL be no tabs row and the windows SHALL start at row 0. Scratch buffers, such as the file tree, SHALL get no tab. The row SHALL be filled in `TabLineFill`.

#### Scenario: A second file shows the row
- **WHEN** "a.txt" is shown and ":e b.txt" is run
- **THEN** row 0 is the buffer tabs row and the first text row of the window is row 1

#### Scenario: One file has no row
- **WHEN** only "a.txt" is listed in one tab page
- **THEN** row 0 is the first text row

### Requirement: A tab per listed file buffer
Each tab SHALL read a space, the file's icon of the icon set, a space, the last segment of the path or `[No Name]`, a space, the `modified` icon when the buffer is modified or a space otherwise, and a space, in list order. The tab of the current window's buffer SHALL be drawn in `TabLineSel`, its icon included, and the other tabs in `TabLine`.

#### Scenario: Two tabs, one modified
- **WHEN** "src/a.rb" is modified and "b.txt" is current, with the unicode icons
- **THEN** row 0 reads " ◈ a.rb ●  • b.txt   " from column 0, the second tab in the selected group

#### Scenario: The selected tab's icon is in the selected group
- **WHEN** "a.rb" is current among two listed files
- **THEN** every cell of its tab, the icon's included, is in `TabLineSel`

### Requirement: Tabs that do not fit are counted at the ends
When the tabs do not fit the row, the row SHALL show a run of whole tabs that includes the current buffer's, preceded by " <N " when N tabs are hidden before it and followed by " N> " when N are hidden after it, both in `TabLine`. The run SHALL start as early as the current tab allows.

#### Scenario: Overflow on both sides
- **WHEN** ten files are listed, the sixth is current, and the row is 40 columns wide
- **THEN** the row starts with " <K " for the K hidden tabs before the run, shows the sixth file's tab selected, and ends its tabs with " M> " for the M hidden after it

### Requirement: Tab-page numbers at the right end
When two or more tab pages exist, the right end of the row SHALL show each tab page's number with a space before and after, in order, the current one in `TabLineSel` and the others in `TabLine`, and the buffer tabs SHALL use only the columns before them.

#### Scenario: Two tab pages
- **WHEN** two tab pages exist, the first current, in a 40-column frame
- **THEN** row 0 ends with " 1  2 " with " 1 " selected

### Requirement: gt and gT move between the buffer tabs
With `option.gt buffers`, the shipped default, "gt" SHALL show the buffer of the next buffer tab in the current window, wrapping from the last tab to the first, "gT" that of the previous one, wrapping, "{count}gT" that of the tab count tabs back, and "{count}gt" that of the count-th tab of the row, doing nothing when the row has fewer tabs. The current tab page SHALL stay, whether one or more tab pages exist, and a modified current file buffer SHALL refuse the move as ":bn" does.

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
- **WHEN** "a.txt" and "b.txt" are listed, "a.txt" is current and modified, and "gt" is typed
- **THEN** the message is "E37: No write since last change (add ! to override)" and the window still shows "a.txt"

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
