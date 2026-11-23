## MODIFIED Requirements

### Requirement: A tab is a name and a mark, with no icon
Each tab SHALL read two spaces, the last segment of the path or `[No Name]`, a space, and the `modified` icon or a space, in list order, with no file icon, gem, or separator glyph, so two tabs stand two blank cells apart. The current tab SHALL be in `TabLineSel`, bold on the editor's background with no accent fill; the others in `TabLine`. Under 16 colors and NO_COLOR the row SHALL have no fill, the current tab bold and every other name in `Normal`.

#### Scenario: Two tabs, one modified
- **WHEN** "src/a.rb" is modified and "b.txt" is current
- **THEN** row 0 reads "  a.rb ●  b.txt" from column 0, the second tab in the selected group, with no `│` in the row

#### Scenario: The selected tab has no icon and no fill
- **WHEN** "a.rb" is current among two listed files
- **THEN** every cell of its tab is in `TabLineSel`, the other tab is in `TabLine`, and no cell of either is a file icon

#### Scenario: Tabs under every icon set
- **WHEN** "a.txt" is current among "a.txt" and "b.txt", with the unicode, nerd, or ascii icons
- **THEN** row 0 reads "  a.txt    b.txt" from column 0, with no icon, gem, `|`, or `*`

#### Scenario: The tab row at 16 colors and NO_COLOR
- **WHEN** two files are listed and the frame is drawn with 16 colors, and again with NO_COLOR
- **THEN** the selected tab is in `TabLineSel`, the other tab is in `Normal`, and the cells past the tabs are in `Normal`, with no `TabLineFill`

## ADDED Requirements

### Requirement: Two tabs with one name show their folders
While another listed file has the same last segment of its path, a tab SHALL show the folder holding its file and its slash before the name, dim (`MsgDim` on the selected tab, `TabLine` on the others, the tab's own group under 16 colors and NO_COLOR). Only the last folder SHALL show, `/` for a file in the root; the folder's cells SHALL count in the tab's width. A tab whose name no other listed file has SHALL show none.

#### Scenario: Two files with one name show their folders
- **WHEN** "a/x.rb" and "b/x.rb" are listed with "a/x.rb" current, and again with "b/y.rb" in place of "b/x.rb", and with "~b/x.rb" unlisted
- **THEN** row 0 reads "  a/x.rb    b/x.rb" with the folder "a/" in `MsgDim` and the name in `TabLineSel`, the other tab's folder and name in `TabLine`; with "b/y.rb" it reads "  x.rb    y.rb", and with the second file unlisted "  x.rb"

#### Scenario: A shared name's folder counts in the overflow
- **WHEN** "a/x.rb" and "b/x.rb" are listed with "a/x.rb" current in a 19-column row, and in a 20-column row
- **THEN** the 19-column row reads "  a/x.rb   1>" and the 20-column row shows both tabs
