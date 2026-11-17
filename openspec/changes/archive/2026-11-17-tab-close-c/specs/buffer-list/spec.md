## MODIFIED Requirements

### Requirement: A buffer switch from a side window acts on the file window
A buffer switch (`gt` and `gT` under `option.gt buffers`, `:bn`, `:bp`, `:b N`, Ctrl-^, the leader and bracket buffer keys) run with the focus in a side window SHALL show the buffer in the tab page's file window, the previously used window when it shows a file, else the first file window, and focus it; the side window SHALL keep its buffer, and a refused switch SHALL leave the focus there and the tab page's previous window as it was.

#### Scenario: gt from the explorer moves the file window's buffer tab
- **WHEN** "alpha.txt" and "beta.txt" are listed, the explorer is open beside the file window showing "alpha.txt", the focus is in the explorer, and "gt" is typed
- **THEN** the explorer is still open and the focused file window shows "beta.txt"

#### Scenario: gT from the explorer moves the file window's buffer tab
- **WHEN** "alpha.txt" and "beta.txt" are listed, the explorer is open beside the file window showing "alpha.txt", the focus is in the explorer, and "gT" is typed
- **THEN** the explorer is still open and the focused file window shows "beta.txt"

#### Scenario: :bn and :bp from the explorer switch the file window
- **WHEN** "alpha.txt" and "beta.txt" are listed, the explorer is open beside the file window showing "alpha.txt", the focus is in the explorer, and ":bn" is run, then the focus returns to the explorer and ":bp" is run
- **THEN** the file window shows "beta.txt" and then "alpha.txt", and the explorer stays open

#### Scenario: A refused switch from a side window keeps the previous window
- **WHEN** a reading view and a file window are open beside the explorer, the explorer is focused from the reading view, and ":b 99" is run
- **THEN** the message is "E86: Buffer 99 does not exist", the focus stays in the explorer, and `<C-w>p` goes back to the reading view

## ADDED Requirements

### Requirement: A buffer switch outside a side window acts on the focused window
A side window is a window of the tab page's sidebar or panel showing a plugin's view, such as the explorer; a window showing a reading view is not one. A buffer switch run in any window that is not a side window SHALL act on that window, alone or beside other windows.

#### Scenario: Buffer switches from a lone reading view act on its window
- **WHEN** the only window shows the reading view of "notes.md" and ":bn", ":bp", ":b N", Ctrl-^, or "gt" is run
- **THEN** that window shows the buffer the command names, it stays the only window, and no message shows

#### Scenario: Buffer switches from a reading view in a split act on the focused window
- **WHEN** the reading view of "notes.md" is focused in a split beside a window showing "alpha.txt" and ":bn", ":bp", ":b N", Ctrl-^, or "gt" is run
- **THEN** the focused window shows the buffer the command names and the other window still shows "alpha.txt"
