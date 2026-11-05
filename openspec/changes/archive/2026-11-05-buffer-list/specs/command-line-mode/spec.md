## MODIFIED Requirements

### Requirement: Quit leaves the editor unless changes are unsaved
":q" and ":quit" SHALL close the current window when another window exists in any tab page, its tab page closing with its last window and its buffer staying hidden in the list. On the last window they SHALL end the editor unless a listed file buffer is modified: the current one SHALL be refused with "E37: No write since last change (add ! to override)", another one as the unsaved-changes refusal says. ":q!" and ":quit!" SHALL skip the current buffer and refuse only over a modified hidden one.

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
- **WHEN** a modified buffer "b.txt" is hidden and ":q" is run in the only window
- **THEN** the editor stays, the message is "E37: No write since last change" and "E162: No write since last change for buffer "b.txt"" on two lines, and the window shows "b.txt"

#### Scenario: Forced quit shows the hidden buffer
- **WHEN** a modified buffer "b.txt" is hidden and ":q!" is run in the only window
- **THEN** the editor stays, the message names "b.txt" with E162, and the window shows "b.txt"

### Requirement: Write-quit writes then quits
":wq" SHALL write the buffer as ":w" does and then close the window as ":q" does, refusing over a modified hidden buffer as the unsaved-changes refusal says but not over the buffer just written; if the write fails the editor SHALL stay and show the write error. ":wq!" SHALL do the same with a forced write. ":wq path" SHALL write to that path first.

#### Scenario: Write and quit
- **WHEN** ":wq" is run on a modified buffer for "a.txt" in the only window
- **THEN** "a.txt" holds the buffer text and the editor ends

#### Scenario: Write-quit with no file name
- **WHEN** ":wq" is run on a buffer with no path
- **THEN** the editor stays and the message is "E32: No file name"

#### Scenario: Write-quit one of two windows
- **WHEN** the window is split, "x" is pressed, and ":wq" is run
- **THEN** the file is written, one window remains, and the editor is still running

#### Scenario: Write-quit refused by a hidden buffer
- **WHEN** a modified buffer "b.txt" is hidden and ":wq" is run on "a.txt" in the only window
- **THEN** "a.txt" is written, the editor stays, the message names "b.txt" with E162, and the window shows "b.txt"

### Requirement: Edit opens a file or reloads the current one
":e path" and ":edit path" SHALL show the file in the current window: the listed buffer for that path, with the cursor where a window last left it, else the file read from disk, or an empty buffer if it does not exist, with the cursor at (0, 0). ":e" alone or with the buffer's own path SHALL reload the buffer in place. Both SHALL be refused with E37 on a modified buffer unless the bang is used, which discards the changes. The buffer left SHALL stay listed, hidden, as the buffer list requires.

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

#### Scenario: The buffer left stays listed
- **WHEN** ":e b.txt" is run on an unmodified "a.txt"
- **THEN** "a.txt" is still listed, hidden

### Requirement: Write-all writes every modified buffer
":wa", ":wall", and their bang forms SHALL write every modified buffer in the list, in list order across every tab page, to its own path with the message of ":w", clear its modified flag, and show the message of the last write. An unmodified buffer and a plugin's scratch buffer SHALL be neither written nor reported. A modified buffer with no path SHALL report "E141: No file name for buffer N", N being its buffer number; the others SHALL still be written and the first failure shown.

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

#### Scenario: Write-all skips a scratch buffer
- **WHEN** a plugin's scratch window is open with edited lines, "a.txt" is modified in the other window, and ":wa" is run
- **THEN** "a.txt" is written, the message is its written message, and no E141 is reported

#### Scenario: The number does not shift
- **WHEN** "a.txt" is buffer 1, ":e b.txt" makes buffer 2, ":new" opens an unnamed buffer 3, "ix" is typed in it, ":bd 1" is run, and ":wa" is run
- **THEN** the message is "E141: No file name for buffer 3"

### Requirement: Quit-all leaves the editor unless changes are unsaved
":qa", ":qall", ":quita", and ":quitall" SHALL end the editor, closing every window of every tab page, when no file buffer in the list is modified, and SHALL otherwise be refused as the unsaved-changes refusal says, naming the first modified buffer among the current buffer, those of the current tab page's windows, those of the other tab pages in order, and the rest of the list. Their bang forms SHALL end the editor regardless, without writing.

#### Scenario: Quit-all a clean buffer
- **WHEN** ":qa" is run on an unmodified buffer
- **THEN** the editor ends

#### Scenario: Quit-all refused
- **WHEN** ":qa" is run on a modified buffer for "a.txt"
- **THEN** the editor stays and the message is "E37: No write since last change" and "E162: No write since last change for buffer "a.txt"" on two lines

#### Scenario: Forced quit-all
- **WHEN** ":qa!" is run on a modified buffer
- **THEN** the editor ends and the file is not written

#### Scenario: Long forms
- **WHEN** ":qall", ":quita", or ":quitall" is run on a modified buffer, and then with a bang
- **THEN** each is refused with E37 and E162 without the bang and ends the editor with it

#### Scenario: Quit-all with several windows
- **WHEN** the window is split, ":tabnew" is run, every buffer is unmodified, and ":qa" is run
- **THEN** the editor ends

#### Scenario: Quit-all refused by another tab page
- **WHEN** ":tabe b.txt" is run, "x" is pressed, "gt" returns to the first tab page, and ":qa" is run
- **THEN** the editor stays, the message names "b.txt" with E162, and the second tab page is current

#### Scenario: Quit-all shows a hidden buffer
- **WHEN** ":sp b.txt" is run, "x" is pressed, `<C-w>c` closes that window, and ":qa" is run
- **THEN** the editor stays, the message names "b.txt" with E162, and the window shows "b.txt"

## ADDED Requirements

### Requirement: Quitting is refused over another buffer's unsaved changes
When ":qa", or ":q", ":q!", ":wq", or ":x" on the last window, is refused because of a modified file buffer it does not refuse with the single E37 line, the message SHALL be the two lines "E37: No write since last change" and "E162: No write since last change for buffer "name"", name being the buffer's path or "[No Name]", and the editor SHALL go to that buffer: to the first window showing it, making its tab page current, or else show it in the current window.

#### Scenario: Exit refused by a hidden buffer
- **WHEN** a modified buffer "b.txt" is hidden and ":x" is run on the unmodified "a.txt" in the only window
- **THEN** the editor stays, the message names "b.txt" with E162, and the window shows "b.txt"

#### Scenario: An unnamed buffer
- **WHEN** ":new" opens an unnamed buffer, "ix" is typed in it, ":q!" closes its window, and ":qa" is run
- **THEN** the message is "E37: No write since last change" and "E162: No write since last change for buffer "[No Name]"" on two lines
