## MODIFIED Requirements

### Requirement: A tab per listed file buffer
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

### Requirement: Tab-page numbers at the right end
When two or more tab pages exist, the right end of the row SHALL show each tab page's number with a space before and after, in order, the current one bold in `TabLineName` and the others dim in `TabLine`, with no accent fill, and the buffer tabs SHALL use only the columns before them. Under 16 colors and NO_COLOR the current one SHALL be in `TabLineSel` and the others in `Normal`. `gt` SHALL move between the buffer tabs and the tab pages are the numbers at the right, under `option.gt` as before.

#### Scenario: Two tab pages
- **WHEN** two tab pages exist, the first current, in a 40-column frame
- **THEN** row 0 ends with " 1  2 " with " 1 " in `TabLineName` and " 2 " in `TabLine`
