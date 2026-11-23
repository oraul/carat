## ADDED Requirements

### Requirement: The file's tab stays selected while a sidebar has focus
While a sidebar has focus, the selected tab SHALL be that of the buffer in the file window the sidebar opens files in, as it is with that window focused; with no such window no tab SHALL be selected. A focused float SHALL change nothing.

#### Scenario: The file's tab stays selected while a sidebar has focus
- **WHEN** "b.txt" is shown in the file window beside the explorer, "a.txt" and "b.txt" are listed, and the explorer has focus, with and without a previous window to name the file window
- **THEN** the tab of "b.txt" is in `TabLineSel` and the tab of "a.txt" is in `TabLine`, as with the file window focused
