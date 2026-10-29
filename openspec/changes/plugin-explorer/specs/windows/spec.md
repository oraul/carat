# Spec Delta

## MODIFIED Requirements

### Requirement: Quitting a window
`<C-w>q` SHALL do what ":q" does: close the current window when another window exists in any tab page, closing its tab page when it was that tab page's last window, and end the editor as ":q" does otherwise. When the current window shows a file and every other window of its tab page shows a plugin's scratch buffer, it SHALL act as on the tab page's last window: close the tab page with its side windows when other tab pages exist, and otherwise end the editor as ":q" does on the last window. With a count it SHALL quit the window with that number.

#### Scenario: Quit one of two windows
- **WHEN** a window is split and `<C-w>q` is pressed
- **THEN** one window remains and the editor is still running

#### Scenario: Quit the last window
- **WHEN** `<C-w>q` is pressed with one window and one tab page on an unmodified buffer
- **THEN** the editor ends

#### Scenario: Quit beside a side window
- **WHEN** a plugin's side window is open, the file window is current, and `<C-w>q` is pressed on an unmodified buffer
- **THEN** the editor ends
