## MODIFIED Requirements

### Requirement: Quit leaves the editor unless changes are unsaved
":q" and ":quit" SHALL close the current window when another window exists in any tab page, its tab page closing with its last window and its buffer staying hidden in the list. On the last window, under `option.gt buffers` while another listed file buffer exists, they SHALL close the current buffer's tab as the buffer-tab rule says. Otherwise, on the last window, they SHALL end the editor unless a listed file buffer is modified: the current one SHALL be refused with "E37: No write since last change (add ! to override)", another one as the unsaved-changes refusal says. ":q!" and ":quit!" SHALL skip the current buffer and refuse only over a modified hidden one.

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
- **THEN** the window closes, one window remains showing the other buffer, and ":qa" is then refused with E37 and E162

#### Scenario: Quit refused by a hidden buffer
- **WHEN** `option.gt tabpages` is set, a modified buffer "b.txt" is hidden, and ":q" is run in the only window
- **THEN** the editor stays, the message is "E37: No write since last change" and "E162: No write since last change for buffer "b.txt"" on two lines, and the window shows "b.txt"

#### Scenario: Forced quit shows the hidden buffer
- **WHEN** `option.gt tabpages` is set, a modified buffer "b.txt" is hidden, and ":q!" is run in the only window
- **THEN** the editor stays, the message names "b.txt" with E162, and the window shows "b.txt"

## ADDED Requirements

### Requirement: Quit closes the buffer tab
Under `option.gt buffers`, where ":q", ":q!", ":wq", ":x", or `<C-w>q` would end the editor and another listed file buffer exists, they SHALL close the current buffer's tab instead: the buffer SHALL leave the list and every window that showed it SHALL show the next listed file buffer, or the one before it, side windows staying. E37 SHALL still refuse ":q" on a modified buffer; ":q!" SHALL discard its changes.

#### Scenario: Quit closes the buffer tab and shows the next
- **WHEN** "a.txt" and "b.txt" are listed, "a.txt" is shown in the only window, and ":q" is run
- **THEN** the editor stays, the window shows "b.txt", and ":ls" lists only "b.txt"

#### Scenario: Quit on the last listed buffer ends the editor
- **WHEN** "a.txt" and "b.txt" are listed, ":q" is run twice
- **THEN** the editor ends

#### Scenario: Quit on a modified buffer with others listed is refused
- **WHEN** "a.txt" and "b.txt" are listed, "x" is pressed on "a.txt", and ":q" is run
- **THEN** the message is E37, the window still shows "a.txt", and both buffers stay listed

#### Scenario: Forced quit closes the buffer tab discarding its changes
- **WHEN** "a.txt" and "b.txt" are listed, "x" is pressed on "a.txt", and ":q!" is run
- **THEN** the editor stays, the window shows "b.txt", and ":ls" lists only "b.txt"

#### Scenario: Quit beside the explorer closes the buffer tab
- **WHEN** the editor starts with no file, the explorer is opened, a file is opened from it in a new tab page, gT is pressed, and ":q" is run
- **THEN** the editor stays, the explorer remains, and only the opened file is listed, with no "[No Name]" tab

#### Scenario: Under tab pages quit on the last window ends the editor
- **WHEN** `option.gt tabpages` is set, "b.txt" is listed and hidden, and ":q" is run on "a.txt" in the only window
- **THEN** the editor ends
