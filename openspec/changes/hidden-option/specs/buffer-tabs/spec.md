## MODIFIED Requirements

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
