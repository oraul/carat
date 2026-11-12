## ADDED Requirements

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
