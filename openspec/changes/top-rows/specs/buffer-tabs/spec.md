## MODIFIED Requirements

### Requirement: A tab per listed file buffer
Each tab SHALL read a space, the file's icon of the icon set, a space, the last segment of the path or `[No Name]`, a space, the `modified` icon when the buffer is modified or a space otherwise, and a space, in list order. The tab of the current window's buffer SHALL be drawn in `TabLineSel`, its icon included, and the other tabs in `TabLine`.

#### Scenario: Two tabs, one modified
- **WHEN** "src/a.rb" is modified and "b.txt" is current, with the unicode icons
- **THEN** row 0 reads " ◈ a.rb ●  • b.txt   " from column 0, the second tab in the selected group

#### Scenario: The selected tab's icon is in the selected group
- **WHEN** "a.rb" is current among two listed files
- **THEN** every cell of its tab, the icon's included, is in `TabLineSel`

## ADDED Requirements

### Requirement: The modified mark takes one cell
A tab's modified mark SHALL take exactly one cell, so a tab is as wide modified as unmodified; a `modified` icon wider than one cell SHALL be replaced by the ASCII set's.

#### Scenario: The modified mark keeps the tab's width
- **WHEN** "a.rb" and "b.txt" are listed and "a.rb" is modified, with the nerd, the unicode, or the ascii icons
- **THEN** the tab of "b.txt" starts at the column it starts at when "a.rb" is unmodified
