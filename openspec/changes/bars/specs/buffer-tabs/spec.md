## ADDED Requirements

### Requirement: Buffer tabs take the top row from two buffers or two tab pages
When two or more file buffers are listed or two or more tab pages exist, row 0 SHALL be the buffer tabs row and the windows SHALL be laid out from row 1; otherwise there SHALL be no tabs row and the windows SHALL start at row 0. Scratch buffers, such as the file tree, SHALL get no tab. The row SHALL be filled in `TabLineFill`.

#### Scenario: A second file shows the row
- **WHEN** "a.txt" is shown and ":e b.txt" is run
- **THEN** row 0 is the buffer tabs row and the first text row of the window is row 1

#### Scenario: One file has no row
- **WHEN** only "a.txt" is listed in one tab page
- **THEN** row 0 is the first text row

### Requirement: A tab per listed file buffer
Each tab SHALL read a space, the file's icon of the icon set, a space, the last segment of the path or `[No Name]`, a space, the `modified` icon when the buffer is modified or a space otherwise, and a space, in list order. The tab of the current window's buffer SHALL be drawn in `TabLineSel` with its icon in the file-icon group of the file, and the other tabs in `TabLine`.

#### Scenario: Two tabs, one modified
- **WHEN** "src/a.rb" is modified and "b.txt" is current, with the unicode icons
- **THEN** row 0 reads " ◈ a.rb ●  • b.txt   " from column 0, the second tab in the selected group

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
