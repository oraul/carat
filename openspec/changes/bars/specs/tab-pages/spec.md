## REMOVED Requirements

### Requirement: The tab line lists the tab pages when there are several
**Reason**: The top row lists the listed file buffers, with the tab-page numbers at its right end from two tab pages, instead of one label per tab page.
**Migration**: The `buffer-tabs` capability states the buffer tabs and the tab-page numbers.

## ADDED Requirements

### Requirement: The tab pages are numbered at the right of the top row
When two or more tab pages exist, the top row SHALL show the buffer tabs and, at its right end, the tab-page numbers with the current one selected; with one tab page and one listed file buffer there SHALL be no top row.

#### Scenario: Two tab pages
- **WHEN** "a.txt" is shown and ":tabe b.txt" is run
- **THEN** row 0 shows a tab for "a.txt" and a selected tab for "b.txt", ends with " 1  2 " with " 2 " selected, and the first text row of the window is row 1

#### Scenario: Back to one tab page
- **WHEN** ":tabnew" then ":tabclose" are run with only "a.txt" listed
- **THEN** row 0 is the first text row of the window
