# Spec Delta

## ADDED Requirements

### Requirement: Quitting beside plugin side windows quits the tab page
A window that shows a file while every other window of its tab page shows a plugin's scratch buffer SHALL count as the tab page's last window for ":q", ":wq", and ":x", taking precedence over closing it alone: its tab page SHALL close with the side windows when other tab pages exist, and otherwise the last-window rule SHALL apply, with its E37 check and its bang.

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
