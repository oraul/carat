## ADDED Requirements

### Requirement: A buffer switch from a side window acts on the file window
A buffer switch (`gt` and `gT` under `option.gt buffers`, `:bn`, `:bp`, `:b N`, Ctrl-^, the leader and bracket buffer keys) run with the focus in a side window SHALL show the buffer in the tab page's file window, the previously used window when it shows a file, else the first file window, and focus it; the side window SHALL keep its buffer, and a refused switch SHALL leave the focus there.

#### Scenario: gt from the explorer moves the file window's buffer tab
- **WHEN** "alpha.txt" and "beta.txt" are listed, the explorer is open beside the file window showing "alpha.txt", the focus is in the explorer, and "gt" is typed
- **THEN** the explorer is still open and the focused file window shows "beta.txt"

#### Scenario: gT from the explorer moves the file window's buffer tab
- **WHEN** "alpha.txt" and "beta.txt" are listed, the explorer is open beside the file window showing "alpha.txt", the focus is in the explorer, and "gT" is typed
- **THEN** the explorer is still open and the focused file window shows "beta.txt"

#### Scenario: :bn and :bp from the explorer switch the file window
- **WHEN** "alpha.txt" and "beta.txt" are listed, the explorer is open beside the file window showing "alpha.txt", the focus is in the explorer, and ":bn" is run, then the focus returns to the explorer and ":bp" is run
- **THEN** the file window shows "beta.txt" and then "alpha.txt", and the explorer stays open

### Requirement: A buffer switch with no file window is refused
With no file window in the tab page, a buffer switch from a side window SHALL leave the side window's buffer and SHALL show "No file window to show the buffer in".

#### Scenario: A switch from a lone side window is refused
- **WHEN** only the explorer is left in the tab page and ":bn" is run in it
- **THEN** the explorer keeps its buffer and the message is "No file window to show the buffer in"
