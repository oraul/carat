## MODIFIED Requirements

### Requirement: A tab per listed file buffer
Each tab SHALL read a space, a space, the file's icon, a space, the last segment of the path or `[No Name]`, a space, the `modified` icon or a space, a space, and a separator `│` (`|` with ascii), in list order, and draw no gem. The current tab SHALL be in `TabLineSel`, its leading space and icon included, so the accent background and the bold carry the selection; the others and every separator in `TabLine`.

#### Scenario: Two tabs, one modified
- **WHEN** "src/a.rb" is modified and "b.txt" is current, with the unicode icons
- **THEN** row 0 reads "  ◈ a.rb ● │  • b.txt   │" from column 0, the second tab in the selected group

#### Scenario: The selected tab's icon is in the selected group
- **WHEN** "a.rb" is current among two listed files
- **THEN** every cell of its tab but the separator, the leading space and the icon included, is in `TabLineSel`, and the separator and the other tab are in `TabLine`

#### Scenario: The ascii icons give the ascii separator and no gem
- **WHEN** "a.txt" is current among "a.txt" and "b.txt", with the ascii icons
- **THEN** row 0 reads "  . a.txt   |  . b.txt   |" from column 0, with no gem and no `*`
