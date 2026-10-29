# Spec Delta

## ADDED Requirements

### Requirement: Plugin side windows do not keep a tab page open
When the current window shows a file and every other window of its tab page shows a plugin's scratch buffer, `<C-w>q` SHALL treat it as the tab page's last window, taking precedence over closing it alone: it SHALL close the tab page with its side windows when other tab pages exist, and otherwise end the editor as ":q" does on the last window.

#### Scenario: Quit beside a side window
- **WHEN** a plugin's side window is open, the file window is current, and `<C-w>q` is pressed on an unmodified buffer
- **THEN** the editor ends

#### Scenario: Quit in the side window
- **WHEN** a plugin's side window is current and `<C-w>q` is pressed
- **THEN** only the side window closes
