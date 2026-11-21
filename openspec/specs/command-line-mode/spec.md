# command-line-mode Specification

## Purpose
Command-line mode lets the user type an ex command after ":" and run it with Enter. This capability covers editing the command line and the file commands :w, :q, :wq, :x, :wa, :qa, :wqa, :xa, and :e with their bang and long forms, with Vim's messages for success and failure.

## Requirements

### Requirement: Colon enters command-line mode
Pressing ":" in normal mode SHALL enter command-line mode with an empty command line, shown on the bottom row prefixed by ":" with the cursor after the text.

#### Scenario: Enter the command line
- **WHEN** ":" is pressed in normal mode
- **THEN** the mode is cmdline and the bottom row shows ":"

### Requirement: The command line is edited with typed keys
In command-line mode printable keys SHALL insert at the cursor of the command line, Backspace SHALL remove the character before the cursor, Backspace on an empty command line SHALL return to normal mode, and Escape SHALL discard the command line and return to normal mode.

#### Scenario: Typing and correcting
- **WHEN** ":", "w", "x", Backspace are pressed
- **THEN** the bottom row shows ":w"

#### Scenario: Backspace on empty leaves
- **WHEN** ":" then Backspace are pressed
- **THEN** the mode is normal and the bottom row is empty

#### Scenario: Escape discards
- **WHEN** ":", "w", Escape are pressed on a modified buffer
- **THEN** the mode is normal and no file is written

### Requirement: Enter executes the command and returns to normal mode
Enter SHALL run the command line as an ex command and return to normal mode, showing the command's message if it produced one. An empty command line SHALL do nothing.

#### Scenario: Empty command
- **WHEN** ":" then Enter are pressed
- **THEN** the mode is normal and nothing else changes

### Requirement: Unknown commands report E492
A command whose name is not an editor command SHALL show "E492: Not an editor command: " followed by the text typed, and change nothing.

#### Scenario: Unknown command
- **WHEN** ":foo" is run
- **THEN** the message is "E492: Not an editor command: foo"

### Requirement: Write saves the buffer
":w" and ":write" SHALL write the buffer's text to its path, clear the modified flag, and show the message in Vim's form: the quoted path, then the line count with "L", the byte count with "B", and "written", for example "\"a.txt\" 2L, 8B written". With an argument the command SHALL write to that path instead and, when the buffer had no path, adopt it. A buffer with no path and no argument SHALL report "E32: No file name".

#### Scenario: Write an edited file
- **WHEN** the buffer for "a.txt" holds ["one", "two"] after an edit and ":w" is run
- **THEN** the file "a.txt" contains "one\ntwo\n", the buffer is unmodified, and the message is "\"a.txt\" 2L, 8B written"

#### Scenario: Long form
- **WHEN** ":write" is run on the same buffer
- **THEN** the file is written and the same message shown

#### Scenario: Write to another path
- **WHEN** ":w b.txt" is run on the buffer for "a.txt"
- **THEN** "b.txt" contains the text, "a.txt" is untouched, and the buffer path stays "a.txt"

#### Scenario: No file name
- **WHEN** ":w" is run on a buffer with no path
- **THEN** the message is "E32: No file name" and nothing is written

#### Scenario: Write failure is reported
- **WHEN** ":w" is run and the file cannot be written
- **THEN** the message starts with "E212: Can't open file for writing" and the buffer stays modified

### Requirement: Quit leaves the editor unless changes are unsaved
":q" and ":quit" SHALL close the current window when another window exists in any tab page, its buffer staying hidden. On the last window they SHALL close the buffer tab as the buffer-tab rule says when it applies, and otherwise end the editor unless a listed file buffer is modified: the current one SHALL be refused with "E37: No write since last change (add ! to override)", another one as the unsaved-changes refusal says. ":q!" SHALL skip the current buffer.

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

### Requirement: Command names accept a bang and an argument
A command line SHALL be parsed as a name of letters, an optional "!" directly after it, and the rest after whitespace as the argument. Leading and trailing whitespace and leading colons SHALL be ignored.

#### Scenario: Bang and argument
- **WHEN** the command line "w! out.txt" is parsed
- **THEN** the name is "w", bang is set, and the argument is "out.txt"

#### Scenario: Leading colon and spaces
- **WHEN** the command line " :q " is parsed
- **THEN** the name is "q", bang is not set, and the argument is empty

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

### Requirement: Ex command names are recognized from their abbreviation to their full name
Every ex command SHALL be recognized when typed as its abbreviation, its full name, or any spelling between them that starts the full name, as Vim's notation name[suffix] means; a shorter spelling or one that does not start the full name SHALL report E492. When two commands accept the typed name, the first in the registered order SHALL run.

#### Scenario: Vertical split abbreviated
- **WHEN** ":vsp" is run in a window of 24 rows and 80 columns
- **THEN** the window is split vertically as ":vsplit" splits it

#### Scenario: Write abbreviated between its forms
- **WHEN** the buffer "a.txt" is modified and ":wr" is run
- **THEN** the buffer is written as ":write" writes it

#### Scenario: Write-all and exit abbreviated
- **WHEN** ":wal" is run over a modified buffer, and later ":xi" over a clean one
- **THEN** ":wal" writes as ":wall" does and ":xi" leaves the editor as ":xit" does

#### Scenario: Tab page commands abbreviated
- **WHEN** three tab pages are open, the third is current, and ":tabfirs" is run
- **THEN** the first tab page is current

#### Scenario: Too short or not a prefix
- **WHEN** ":tabf" or ":vsplitx" is run
- **THEN** the message is "E492: Not an editor command: tabf" or "E492: Not an editor command: vsplitx"

### Requirement: Edit names the first line with an illegal byte
":e path" of a file that is not valid UTF-8 SHALL open it like any other file and SHALL add "[ILLEGAL BYTE in line N]", N being the first line holding a byte outside a well-formed UTF-8 sequence, between the quoted file name and the line and byte counts. A failure to read or load the file SHALL be answered with an E484 message and SHALL leave the editor running.

#### Scenario: Open a Latin-1 file
- **WHEN** ":e l.txt" is run and "l.txt" holds "ok\ncaf\xE9\n"
- **THEN** the lines are ["ok", "caf\xE9"] and the message is "\"l.txt\" [ILLEGAL BYTE in line 2] 2L, 8B"

#### Scenario: Write an unedited file with an illegal byte
- **WHEN** "l.txt" holding "ok\ncaf\xE9\n" is opened and ":w" is run
- **THEN** the file holds "ok\ncaf\xE9\n" again

### Requirement: Edit refuses what is not a regular file of bounded size
":e path", and every other way a file is opened in a window, SHALL refuse a directory with `"path" is a directory`, a FIFO, a device, or a socket with `"path" is not a file`, and a file of more than 67108864 bytes with `E484: Can't open file path: File too large`, each as an error, leaving the current window and buffer as they were. Opening SHALL never wait for a writer or read more than the limit.

#### Scenario: Edit a directory
- **WHEN** the user types ":e lib" and "lib" is a directory
- **THEN** the message row shows "\"lib\" is a directory" as an error and the current buffer is unchanged

#### Scenario: Edit a FIFO
- **WHEN** the user types ":e pipe" and "pipe" is a FIFO with no writer
- **THEN** the message row shows "\"pipe\" is not a file" as an error and the editor keeps running

#### Scenario: Edit a device
- **WHEN** the user types ":e /dev/zero"
- **THEN** the message row shows "\"/dev/zero\" is not a file" as an error

#### Scenario: Edit a huge file
- **WHEN** the user types ":e big.bin" and "big.bin" holds 67108865 bytes
- **THEN** the message row shows "E484: Can't open file big.bin: File too large" as an error

#### Scenario: A linked regular file opens
- **WHEN** the user types ":e link.txt" and "link.txt" is a symbolic link to a regular file
- **THEN** the file opens as any other file

### Requirement: The command line keeps a history
Each command line run at the ":" prompt SHALL be added to the command history, the newest last, without duplicates and at most 50 entries. At the ":" prompt "<Up>" SHALL replace the text with the next older entry that starts with what was typed before the first recall, and "<Down>" with the next newer one, returning to the typed text after the newest; with no such entry the text SHALL stay.

#### Scenario: Recall the last command
- **WHEN** ":set ft?" is run, then ":", "<Up>" are pressed
- **THEN** the command line shows "set ft?"

#### Scenario: Down returns to the typed text
- **WHEN** ":set ft?" is run, then ":", "s", "<Up>", "<Down>" are pressed
- **THEN** the command line shows "s"

### Requirement: Ex commands take a range of lines
A command line SHALL accept a range before the command name: `%` for every line, `.` for the cursor line, `$` for the last line, a line number, and `'<` and `'>` for the first and last line of the window's last visual selection, as one address or two joined by `,`, an empty address standing for the cursor line.

#### Scenario: Whole buffer
- **WHEN** ":%s/a/b/" is run on a buffer of three lines each holding "a"
- **THEN** every line holds "b"

#### Scenario: Two numbers
- **WHEN** ":2,3s/a/b/" is run on a buffer of four lines each holding "a"
- **THEN** lines 2 and 3 hold "b" and lines 1 and 4 hold "a"

#### Scenario: Visual marks
- **WHEN** lines 2 and 3 were selected with "V" and left, and ":'<,'>s/a/b/" is run
- **THEN** only lines 2 and 3 change

### Requirement: A wrong range is refused
A range reaching past the last line SHALL report "E16: Invalid range", a first address after the second "E493: Backwards range given", `'<` or `'>` with no selection "E20: Mark not set", a range before a command that takes none "E481: No range allowed", and an address with `+`, `-`, `;`, a pattern, or another mark "Not implemented: range " followed by the range; none SHALL change anything.

#### Scenario: Past the end
- **WHEN** ":5s/a/b/" is run on a buffer of three lines
- **THEN** the message is "E16: Invalid range" and nothing changes

#### Scenario: Backwards
- **WHEN** ":3,1s/a/b/" is run
- **THEN** the message is "E493: Backwards range given" and nothing changes

#### Scenario: No selection yet
- **WHEN** ":'<,'>s/a/b/" is run in a window that never had a visual selection
- **THEN** the message is "E20: Mark not set"

#### Scenario: A command that takes no range
- **WHEN** ":1,2w" is run
- **THEN** the message is "E481: No range allowed" and nothing is written

### Requirement: A range alone moves the cursor
A command line holding only a range SHALL move the cursor to the range's last line, keeping the wanted column as `G` does, and report nothing.

#### Scenario: Go to a line
- **WHEN** ":3" is run on a buffer of five lines
- **THEN** the cursor is on line 3

#### Scenario: Go to the last line
- **WHEN** ":$" is run
- **THEN** the cursor is on the last line

### Requirement: Colon in a visual mode opens a range of the selection
Pressing ":" in visual, visual line, or visual block mode SHALL leave the mode, keeping the selection as the last one, and enter command-line mode with "'<,'>" on the command line.

#### Scenario: Colon after a linewise selection
- **WHEN** "Vj:" is typed
- **THEN** the mode is cmdline and the command line holds "'<,'>"

### Requirement: Quitting is refused over another buffer's unsaved changes
When ":qa", or ":q", ":q!", ":wq", or ":x" on the last window, is refused because of a modified file buffer it does not refuse with the single E37 line, the message SHALL be the two lines "E37: No write since last change" and "E162: No write since last change for buffer "name"", name being the buffer's path or "[No Name]", and the editor SHALL go to that buffer: to the first window showing it, making its tab page current, or else show it in the current window.

#### Scenario: Exit refused by a hidden buffer
- **WHEN** a modified buffer "b.txt" is hidden and ":x" is run on the unmodified "a.txt" in the only window
- **THEN** the editor stays, the message names "b.txt" with E162, and the window shows "b.txt"

#### Scenario: An unnamed buffer
- **WHEN** ":new" opens an unnamed buffer, "ix" is typed in it, ":q!" closes its window, and ":qa" is run
- **THEN** the message is "E37: No write since last change" and "E162: No write since last change for buffer "[No Name]"" on two lines

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

### Requirement: The command line has a cursor
The command line, the `/` and `?` prompts, the command palette's prompt, and a plugin's prompt SHALL keep a cursor between two characters of the text, at the end when the line opens and after a recall from the history; a character is a code point, a wide character one move. Typed text SHALL insert at the cursor and leave it after the inserted text.

#### Scenario: Insert in the middle of the line
- **WHEN** ":", "w", "q", `<Left>`, "a", "b" are pressed
- **THEN** the bottom row shows ":wabq" and the cursor is after "wab"

#### Scenario: The search prompt has the cursor
- **WHEN** "/", "a", "c", `<Left>`, "b" are pressed
- **THEN** the bottom row shows "/abc" and the preview matches "abc"

#### Scenario: Recall puts the cursor at the end
- **WHEN** ":set ft?" is run, then ":", `<Up>`, "x" are pressed
- **THEN** the command line shows "set ft?x"

#### Scenario: Recall then edit
- **WHEN** ":set ft?" is run, then ":", `<Up>`, `<Home>`, `<Del>` are pressed
- **THEN** the command line shows "et ft?"

### Requirement: The cursor moves by character and by word
`<Left>` and `<Right>` SHALL move the cursor one character, `<Home>` and `<C-b>` to the start, `<End>` and `<C-e>` to the end, and `<S-Left>` or `<C-Left>`, and `<S-Right>` or `<C-Right>`, one blank-separated word back or forward, none past either end of the text.

#### Scenario: Left and Right move the cursor
- **WHEN** ":", "a", "b", "c", `<Left>`, `<Left>`, "X" are pressed
- **THEN** the bottom row shows ":aXbc" and `<Right>` then "Y" gives ":aXbYc"

#### Scenario: The cursor stays inside the line
- **WHEN** ":", "a", `<Right>`, `<Left>`, `<Left>`, `<Left>`, "X" are pressed
- **THEN** the bottom row shows ":Xa"

#### Scenario: Home and End
- **WHEN** ":", "b", "c", `<Home>`, "a", `<End>`, "d" are pressed
- **THEN** the bottom row shows ":abcd"

#### Scenario: Control-b and Control-e
- **WHEN** ":", "b", "c", `<C-b>`, "a", `<C-e>`, "d" are pressed
- **THEN** the bottom row shows ":abcd"

#### Scenario: Words move by blank-separated word
- **WHEN** ":", "e a/b.rb c", `<S-Left>`, `<C-Left>`, "X" are pressed
- **THEN** the bottom row shows ":e Xa/b.rb c", and with `<Home>`, `<C-Right>`, `<S-Right>`, "Y" instead it shows ":e a/b.rb Yc"

#### Scenario: Movement over multi-byte and wide text
- **WHEN** ":", "é", "日", "z", `<Left>`, `<Left>`, "X" are pressed
- **THEN** the bottom row shows ":éX日z", and with one `<Left>` it shows ":é日Xz"

### Requirement: The cursor is drawn as the bar at its cell
The terminal cursor of the command line SHALL be the bar at the display column of the prompt's width plus the width of the text before the cursor, a wide character counting two cells.

#### Scenario: The bar is at the cursor cell
- **WHEN** ":", "a", "b", `<Left>` are pressed
- **THEN** the cursor is the bar at column 2, after the ":" and the "a"

#### Scenario: The bar counts wide characters and the prompt
- **WHEN** a plugin prompt with the text "Rename to: " holds "日" and "a" and the cursor is between them
- **THEN** the cursor column is the width of the prompt plus the two cells of the wide character

### Requirement: Backspace and Delete remove one character
`<BS>` SHALL remove the character before the cursor and do nothing at the start of a non-empty line; `<Del>` SHALL remove the character under the cursor, and at the end of the line act as `<BS>`. A search prompt SHALL preview its pattern again after each change.

#### Scenario: Backspace removes before the cursor
- **WHEN** ":", "a", "b", "c", `<Left>`, `<BS>` are pressed
- **THEN** the bottom row shows ":ac"

#### Scenario: Backspace at the start does nothing
- **WHEN** ":", "a", `<Home>`, `<BS>` are pressed
- **THEN** the mode is cmdline and the bottom row shows ":a"

#### Scenario: Delete removes the character under the cursor
- **WHEN** ":", "a", "b", "c", `<Home>`, `<Del>` are pressed
- **THEN** the bottom row shows ":bc"

#### Scenario: Delete at the end acts as Backspace
- **WHEN** ":", "a", "b", `<Del>` are pressed
- **THEN** the bottom row shows ":a", and `<Del>` on an empty line returns to normal mode

#### Scenario: The search prompt previews after a deletion
- **WHEN** "/", "a", "c", "b", `<Left>`, `<BS>` are pressed
- **THEN** the bottom row shows "/ab" and the preview matches "ab"

### Requirement: Control-w and Control-u remove a word and a line
`<C-w>` SHALL remove the word before the cursor, skipping blanks first and then one run of word characters or one run of other non-blank characters; `<C-u>` SHALL remove everything before the cursor; both SHALL do nothing on an empty line.

#### Scenario: Control-w removes the word before the cursor
- **WHEN** ":", "e app/models" are typed and `<C-w>` is pressed four times
- **THEN** the bottom row shows ":e app/", then ":e app", then ":e ", then ":"

#### Scenario: Control-w works at the cursor in the middle
- **WHEN** ":", "ab cd", `<Left>`, `<Left>`, `<C-w>` are pressed
- **THEN** the bottom row shows ":cd" with the cursor at its start

#### Scenario: Control-u removes everything before the cursor
- **WHEN** ":", "abcd", `<Left>`, `<Left>`, `<C-u>` are pressed
- **THEN** the bottom row shows ":cd" with the cursor at its start

#### Scenario: Control-w and Control-u on an empty line do nothing
- **WHEN** ":", `<C-w>`, `<C-u>` are pressed
- **THEN** the mode is cmdline and the bottom row shows ":"
