# Spec Delta

## MODIFIED Requirements

### Requirement: Quit leaves the editor unless changes are unsaved
:q" and ":quit" SHALL close the current window when another window exists in any tab page, closing its tab page when it was the last window there and keeping a modified buffer hidden in the list. On the last window of the last tab page they SHALL end the editor unless a listed buffer is modified, when they SHALL show "E37: No write since last change (add ! to override)". ":q!" and ":quit!" SHALL skip the check, except that on the last window a modified hidden buffer is shown instead of ending.

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

### Requirement: Write-quit writes then quits
":wq" SHALL write the buffer as ":w" does and then close the window as ":q!" does, ending the editor when it was the last window of the last tab page; if the write fails the editor SHALL stay and show the write error. ":wq!" SHALL do the same with a forced write. ":wq path" SHALL write to that path first.

#### Scenario: Write and quit
- **WHEN** ":wq" is run on a modified buffer for "a.txt" in the only window
- **THEN** "a.txt" holds the buffer text and the editor ends

#### Scenario: Write-quit with no file name
- **WHEN** ":wq" is run on a buffer with no path
- **THEN** the editor stays and the message is "E32: No file name"

#### Scenario: Write-quit one of two windows
- **WHEN** the window is split, "x" is pressed, and ":wq" is run
- **THEN** the file is written, one window remains, and the editor is still running

### Requirement: Edit opens a file or reloads the current one
:e path" and ":edit path" SHALL show the file in the current window: the listed buffer for that path when there is one, else the file read from disk, or an empty buffer if it does not exist, with the cursor at (0, 0). ":e" with no argument or with the current buffer's own path SHALL reload the file into the buffer in place. Both SHALL be refused with E37 when the buffer is modified unless the bang form is used, which discards the changes. A buffer no window shows afterwards SHALL leave the list.

#### Scenario: Open another file
- **WHEN** ":e b.txt" is run on an unmodified buffer and "b.txt" holds "zz"
- **THEN** the buffer path is "b.txt", the lines are ["zz"], the cursor is at (0, 0), and the message is "\"b.txt\" 1L, 3B"

#### Scenario: Open a new file
- **WHEN** ":e new.txt" is run and the file does not exist
- **THEN** the buffer path is "new.txt", the lines are [""], and the message is "\"new.txt\" [New]"

#### Scenario: Refused while modified
- **WHEN** ":e b.txt" is run on a modified buffer
- **THEN** the message is "E37: No write since last change (add ! to override)" and the buffer is unchanged

#### Scenario: Forced reload discards changes
- **WHEN** ":e!" is run on a modified buffer for "a.txt"
- **THEN** the lines are those of the file on disk and the buffer is unmodified

#### Scenario: Edit a listed buffer
- **WHEN** ":sp b.txt" is run, "x" is pressed, `<C-w>j` moves to the window showing "a.txt", and ":e b.txt" is run
- **THEN** the window shows the edited "b.txt" lines, the buffer is still modified, and the file is not read again

#### Scenario: Reload is seen by every window
- **WHEN** the window is split, the file "a.txt" changes on disk, and ":e" is run
- **THEN** both windows show the new text of "a.txt"

### Requirement: Write-all writes every modified buffer
:wa", ":wall", and their bang forms SHALL write every modified buffer in the list, in list order across every tab page, to its own path with the message of ":w", clear its modified flag, and show the message of the last write. An unmodified buffer SHALL not be written nor reported. A modified buffer with no path SHALL report "E141: No file name for buffer N", N being its list position from 1; the other buffers SHALL still be written and the first failure SHALL be the message shown.

#### Scenario: Write-all on a modified buffer
- **WHEN** the buffer for "a.txt" holds ["one", "two"] after an edit and ":wa" is run
- **THEN** the file "a.txt" contains "one\ntwo\n", the buffer is unmodified, and the message is "\"a.txt\" 2L, 8B written"

#### Scenario: Write-all on a clean buffer
- **WHEN** ":wa" is run on an unmodified buffer
- **THEN** nothing is written and no message is shown

#### Scenario: Write-all with no file name
- **WHEN** ":wa" is run on a modified buffer with no path
- **THEN** the message is "E141: No file name for buffer 1" and the buffer stays modified

#### Scenario: Long and bang forms
- **WHEN** ":wall", ":wa!", or ":wall!" is run on a modified buffer for "a.txt"
- **THEN** each writes the file as ":wa" does

#### Scenario: Write-all across windows and tab pages
- **WHEN** "a.txt" and "b.txt" are edited in two windows, "c.txt" is edited in another tab page, and ":wa" is run
- **THEN** all three files hold their buffers' text and every buffer is unmodified

#### Scenario: Write-all reports a nameless buffer
- **WHEN** ":new" opens an unnamed buffer, "ix" is typed in it, "a.txt" is modified in the other window, and ":wa" is run
- **THEN** the message is "E141: No file name for buffer 2", "a.txt" is written, and the unnamed buffer stays modified

### Requirement: Quit-all leaves the editor unless changes are unsaved
":qa", ":qall", ":quita", and ":quitall" SHALL end the editor, closing every window of every tab page, when no buffer in the list is modified, and SHALL show "E37: No write since last change (add ! to override)" and stay otherwise. Their bang forms SHALL end the editor regardless of the modified flags without writing.

#### Scenario: Quit-all a clean buffer
- **WHEN** ":qa" is run on an unmodified buffer
- **THEN** the editor ends

#### Scenario: Quit-all refused
- **WHEN** ":qa" is run on a modified buffer
- **THEN** the editor stays and the message is "E37: No write since last change (add ! to override)"

#### Scenario: Forced quit-all
- **WHEN** ":qa!" is run on a modified buffer
- **THEN** the editor ends and the file is not written

#### Scenario: Long forms
- **WHEN** ":qall", ":quita", or ":quitall" is run on a modified buffer, and then with a bang
- **THEN** each is refused with E37 without the bang and ends the editor with it

#### Scenario: Quit-all with several windows
- **WHEN** the window is split, ":tabnew" is run, every buffer is unmodified, and ":qa" is run
- **THEN** the editor ends

#### Scenario: Quit-all refused by another tab page
- **WHEN** ":tabe b.txt" is run, "x" is pressed, "gt" returns to the first tab page, and ":qa" is run
- **THEN** the editor stays and the message is "E37: No write since last change (add ! to override)"

### Requirement: Write-quit-all writes every modified buffer then quits
":wqa", ":wqall", ":xa", ":xall", and their bang forms SHALL write every modified buffer in every tab page as ":wa" does and then end the editor. An unmodified buffer SHALL not be written and the editor SHALL end. If a write fails, or a modified buffer has no path, the editor SHALL stay and show the write error or "E141: No file name for buffer N".

#### Scenario: Write-quit-all a modified buffer
- **WHEN** ":wqa!" is run on a modified buffer for "a.txt"
- **THEN** "a.txt" holds the buffer text and the editor ends

#### Scenario: Write-quit-all a clean buffer
- **WHEN** ":wqa" is run on an unmodified buffer
- **THEN** the file is not written and the editor ends

#### Scenario: Write-quit-all with no file name
- **WHEN** ":wqa" is run on a modified buffer with no path
- **THEN** the editor stays and the message is "E141: No file name for buffer 1"

#### Scenario: Write-quit-all when the write fails
- **WHEN** ":xa" is run on a modified buffer whose file cannot be written
- **THEN** the editor stays and the message starts with "E212: Can't open file for writing"

#### Scenario: Long and bang forms
- **WHEN** ":wqall", ":xa", ":xall", ":wqa!", ":wqall!", ":xa!", or ":xall!" is run on a modified buffer for "a.txt"
- **THEN** each writes the file and ends the editor as ":wqa" does

#### Scenario: Write-quit-all across tab pages
- **WHEN** "a.txt" is edited in the first tab page, "b.txt" in a second, and ":wqa" is run
- **THEN** both files hold their buffers' text and the editor ends

### Requirement: Exit writes a modified buffer then quits
":x", ":xit", ":exi", and ":exit" SHALL write the buffer as ":w" does when the buffer is modified or a file argument is given, and then close the window as ":q!" does, ending the editor when it was the last window of the last tab page; an unmodified buffer with no argument SHALL not be written. If the write fails the editor SHALL stay and show the write error. The bang forms SHALL behave the same.

#### Scenario: Exit a modified buffer
- **WHEN** ":x" is run on a modified buffer for "a.txt" in the only window
- **THEN** "a.txt" holds the buffer text, the buffer is unmodified, and the editor ends

#### Scenario: Exit a clean buffer
- **WHEN** ":x" is run on an unmodified buffer in the only window
- **THEN** the file is not written, no message is shown, and the editor ends

#### Scenario: Exit with a file argument
- **WHEN** ":x b.txt" is run on an unmodified buffer for "a.txt"
- **THEN** "b.txt" holds the buffer text and the editor ends

#### Scenario: Exit with no file name
- **WHEN** ":x" is run on a modified buffer with no path
- **THEN** the editor stays and the message is "E32: No file name"

#### Scenario: Exit when the write fails
- **WHEN** ":x!" is run on a modified buffer whose file cannot be written
- **THEN** the editor stays, the message starts with "E212: Can't open file for writing", and the buffer stays modified

#### Scenario: Long and bang forms
- **WHEN** ":xit", ":exi", ":exit", ":x!", ":xit!", ":exi!", or ":exit!" is run on a modified buffer for "a.txt"
- **THEN** each writes the file and ends the editor as ":x" does

#### Scenario: Exit one of two windows
- **WHEN** the window is split, "x" is pressed, and ":x" is run
- **THEN** the file is written, one window remains, and the editor is still running
