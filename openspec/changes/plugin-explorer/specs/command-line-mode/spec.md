# Spec Delta

## MODIFIED Requirements

### Requirement: Quit leaves the editor unless changes are unsaved
":q" and ":quit" SHALL close the current window when another window exists in any tab page, closing its tab page when it was the last window there and keeping a modified buffer hidden in the list. On the last window of the last tab page they SHALL end the editor unless a listed buffer is modified, when they SHALL show "E37: No write since last change (add ! to override)". ":q!" and ":quit!" SHALL skip the check, except that on the last window a modified hidden buffer is shown instead of ending. A window that shows a file while every other window of its tab page shows a plugin's scratch buffer SHALL count as the tab page's last window, for ":q", ":wq", and ":x" alike: its tab page closes with the side windows when other tab pages exist, and otherwise the last-window rule applies.

#### Scenario: Quit a clean buffer
- **WHEN** ":q" is run on an unmodified buffer in the only window
- **THEN** the editor ends

#### Scenario: Quit refused
- **WHEN** ":q" is run on a modified buffer in the only window
- **THEN** the editor stays, the message is "E37: No write since last change (add ! to override)", and the mode is normal

#### Scenario: Forced quit
- **WHEN** ":q!" is run on a modified buffer in the only window
- **THEN** the editor ends and the file is not written

#### Scenario: Quit one of two windows
- **WHEN** the window is split and ":q" is run
- **THEN** one window remains and the editor is still running

#### Scenario: Quit the last window showing a modified buffer
- **WHEN** ":sp b.txt" is run, "x" is pressed in the new window, and ":q" is run
- **THEN** the window closes, one window remains showing the other buffer, and ":qa" is then refused with E37

#### Scenario: Quit refused by a hidden buffer
- **WHEN** a modified buffer is hidden and ":q" is run in the only window
- **THEN** the editor stays and the message is "E37: No write since last change (add ! to override)"

#### Scenario: Forced quit shows the hidden buffer
- **WHEN** a modified buffer "b.txt" is hidden and ":q!" is run in the only window
- **THEN** the editor stays and the window shows "b.txt"

#### Scenario: Quit beside a side window
- **WHEN** a plugin's side window is open beside the only file window and ":q" is run there on an unmodified buffer
- **THEN** the editor ends

#### Scenario: Quit beside a side window refused
- **WHEN** a plugin's side window is open beside the only file window and ":q" is run there on a modified buffer
- **THEN** the editor stays with both windows and the message is E37

#### Scenario: Write-quit beside a side window
- **WHEN** a plugin's side window is open beside the only file window and ":wq" is run there
- **THEN** the file is written and the editor ends

#### Scenario: Quit closes the tab page with its side window
- **WHEN** tab page 2 holds a file window and a plugin's side window and ":q" is run in the file window
- **THEN** one tab page remains and the editor is still running

#### Scenario: Quit in the side window
- **WHEN** ":q" is run in the side window
- **THEN** only the side window closes
