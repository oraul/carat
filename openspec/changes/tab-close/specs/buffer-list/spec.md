## MODIFIED Requirements

### Requirement: Deleting a buffer from the list
`:bd`, `:bdelete`, `:bd N`, and `<leader>bd` SHALL remove the current buffer or buffer N from the list. Under `option.gt buffers` every window showing it SHALL stay and show the next listed file buffer, or the one before, or a new empty buffer when none is left, side windows untouched. Under `option.gt tabpages` those windows SHALL close, but the current window while it is the last one, and the last file window of a tab page beside side windows, SHALL stay and show that replacement.

#### Scenario: Delete the current buffer
- **WHEN** "a.txt" and "b.txt" are listed, "a.txt" is current in the only window, and ":bd" is run
- **THEN** the window shows "b.txt" and ":ls" lists only "b.txt"

#### Scenario: Delete the last buffer
- **WHEN** only "a.txt" is listed and ":bd" is run
- **THEN** the window shows an empty unnamed buffer numbered 2 and ":ls" lists only it

#### Scenario: Delete a hidden buffer by number
- **WHEN** "a.txt" is buffer 1, hidden, "b.txt" is current, and ":bd 1" is run
- **THEN** the window still shows "b.txt" and ":ls" lists only "b.txt"

#### Scenario: Delete keeps the windows showing the buffer
- **WHEN** ":sp b.txt" is run, `<C-w>j` moves to "a.txt", and ":bd 2" is run
- **THEN** both windows remain, each showing "a.txt"

#### Scenario: Delete in a split keeps the window
- **WHEN** ":sp b.txt" is run and ":bd" is run in the new window
- **THEN** both windows remain, each showing "a.txt"

#### Scenario: Delete closes the windows showing the buffer
- **WHEN** `option.gt tabpages` is set, ":sp b.txt" is run, `<C-w>j` moves to "a.txt", and ":bd 2" is run
- **THEN** one window remains, showing "a.txt"

#### Scenario: Delete in a split closes the window
- **WHEN** `option.gt tabpages` is set, ":sp b.txt" is run, and ":bd" is run in the new window
- **THEN** one window remains, showing "a.txt"

#### Scenario: Delete beside the explorer keeps every file window
- **WHEN** "alpha.txt" and "beta.txt" are listed, the explorer is open beside tab page 1's file window showing "alpha.txt", a second tab page shows "alpha.txt", and ":bd" is run on "alpha.txt"
- **THEN** the explorer and both file windows remain, each file window showing "beta.txt"

#### Scenario: Delete the last buffer beside the explorer
- **WHEN** the explorer is open beside the file window of the only listed buffer and ":bd" is run there
- **THEN** the explorer and the file window remain, the file window showing a new empty buffer, and `<leader>e` then closes the explorer without E444

#### Scenario: Delete under tab pages keeps the last file window beside the explorer
- **WHEN** `option.gt tabpages` is set, the explorer is open beside the file window of "a.md", "b.rb" is listed, and ":bd" is run there
- **THEN** the explorer and the file window remain, the file window showing "b.rb"

## ADDED Requirements

### Requirement: The startup buffer leaves once a file opens elsewhere
Under `option.gt buffers`, the unnamed, empty, unmodified buffer the editor starts with SHALL leave the list, the top row, and `:ls` as soon as a file opens in another window or tab page, every window that showed it showing the opened file. A file opened over it in its own window SHALL take its number, as before.

#### Scenario: A file opened in a tab page retires the startup buffer
- **WHEN** the editor starts with no file and ":tabe alpha.txt" is run
- **THEN** no "[No Name]" tab is in the top row and ":ls" lists only "alpha.txt"

#### Scenario: A file opened in a split retires the startup buffer
- **WHEN** the editor starts with no file and ":sp alpha.txt" is run
- **THEN** both windows show "alpha.txt" and ":ls" lists only "alpha.txt"

#### Scenario: Under tab pages the startup buffer stays
- **WHEN** `option.gt tabpages` is set, the editor starts with no file, and ":tabe alpha.txt" is run
- **THEN** ":ls" lists the unnamed buffer and "alpha.txt"
