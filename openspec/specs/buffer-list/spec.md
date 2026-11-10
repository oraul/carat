# buffer-list Specification

## Purpose
The buffer list is the set of buffers the editor keeps, each with a stable number: which buffers it holds, how they are listed with `:ls`, how a window moves through them, and how one is deleted.

## Requirements

### Requirement: File buffers stay listed until deleted
A file buffer SHALL stay in the buffer list, hidden, with its text and its changes, when no window shows it any more, whether a window closed, `:e` showed another file, or a buffer command switched away; it SHALL leave the list only through `:bd`. A plugin's scratch buffer SHALL still leave the list when no window shows it.

#### Scenario: Leaving a clean buffer keeps it listed
- **WHEN** the editor starts on "a.txt" and ":e b.txt" is run
- **THEN** ":ls" lists "a.txt" as buffer 1, hidden, and "b.txt" as buffer 2, current

#### Scenario: Closing a window keeps its clean buffer
- **WHEN** ":sp b.txt" is run and the new window is closed with `<C-w>c`
- **THEN** "b.txt" is still listed, hidden

### Requirement: Buffer numbers are stable
Every buffer SHALL keep the number it received when it first entered the list for as long as the editor runs, and no other buffer SHALL receive it. When a file is opened over the unnamed, empty, unmodified buffer of a window that is the only one showing it, the file's buffer SHALL take that buffer's number and the empty buffer SHALL leave the list, so the file opened at startup is buffer 1.

#### Scenario: The empty startup buffer is reused
- **WHEN** the editor starts without a file and ":e a.txt" is run
- **THEN** ":ls" lists only "a.txt", as buffer 1

#### Scenario: A deleted number is not given again
- **WHEN** "a.txt" is buffer 1, ":bd" leaves an empty buffer 2, and ":e b.txt" is run over it
- **THEN** ":ls" lists only "b.txt", as buffer 2

### Requirement: A buffer shown again gets its cursor back
When a window stops showing a buffer, the buffer SHALL remember the window's cursor position, and when a window shows that buffer again through `:e`, `:b`, `:bn`, `:bp`, `:bN`, or `:bd`, the cursor SHALL return there, kept inside the text.

#### Scenario: Back to the remembered line
- **WHEN** on "a.txt" the cursor is moved to line 3, ":e b.txt" is run, and ":b 1" is run
- **THEN** the window shows "a.txt" with the cursor on line 3

### Requirement: Listing the buffers
`:ls`, `:buffers`, and `:files` SHALL list the listed file buffers in list order, one line each: the number right-aligned in three columns, five flag columns, a space, the name in double quotes (the path, a scratch buffer's title, or `[No Name]`), spaces up to display column 40 (at least one), and `line N`. N SHALL be the current window's cursor line for the current buffer and, for another buffer, the line where a window last left it, 1 when none has.

#### Scenario: One buffer
- **WHEN** the editor is on "a.txt" with the cursor on line 1 and ":ls" is run
- **THEN** the message is `  1 %a   "a.txt"                        line 1`

### Requirement: The flags of the buffer listing
The five flag columns of a listing line SHALL be `u` for a buffer that is not listed, else a space; `%` for the buffer of the current window, else a space; `a` for a buffer some window shows, else `h`; `=` for a read-only buffer, else a space; and `+` for a modified file buffer, else a space. With a bang the plugins' scratch buffers SHALL be listed too, flagged `u`.

#### Scenario: Hidden and modified buffers
- **WHEN** "x" is pressed on "a.txt", ":sp b.txt" is run, "x" is pressed there, `<C-w>c` closes that window, and ":ls" is run
- **THEN** the "a.txt" line carries `%a +` and the "b.txt" line `h +`

#### Scenario: Scratch buffers with the bang
- **WHEN** a plugin's side window is open and ":ls!" is run
- **THEN** its scratch buffer is listed with `u` in the first flag column and its title as the name, and ":ls" without the bang leaves it out

#### Scenario: A read-only buffer in the listing
- **WHEN** `gd` showed the read-only buffer of `/gems/c.rb` and ":ls" is run
- **THEN** its line carries `%a=` and the `a.rb` line `h` with a space in the fourth column

### Requirement: Filtering the buffer listing
An argument to `:ls` SHALL keep only the buffers that match every one of its flag characters: `u` the unlisted ones, `+` the modified ones, `a` the shown ones, `h` the hidden ones, `%` the current one, `=` the read-only ones, and `#`, `-`, `x`, `R`, `F`, and `?` none, since no buffer is alternate, unmodifiable, unreadable, or a terminal. Other characters SHALL be ignored.

#### Scenario: Filtered by a flag
- **WHEN** "a.txt" and a hidden "b.txt" are listed and ":ls h" is run
- **THEN** only the "b.txt" line is shown

#### Scenario: Filtered by the read-only flag
- **WHEN** `gd` showed the read-only buffer of `/gems/c.rb` over `a.rb` and ":ls =" is run
- **THEN** only the `c.rb` line is shown

### Requirement: Moving through the buffer list
`:bn`, `:bnext`, `:bp`, `:bprevious`, `:bN`, and `:bNext` SHALL show in the current window the next or the previous listed file buffer, wrapping at the ends, or the Nth one after or before with a number argument, 0 staying. `:b N` and `:buffer N` SHALL show buffer number N, and `:b` alone SHALL stay. Showing the buffer already shown SHALL change nothing.

#### Scenario: Next and previous wrap
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed in that order, "c.txt" is current, and ":bn" is run
- **THEN** the window shows "a.txt", and ":bp" then shows "c.txt" again

#### Scenario: A count
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed, "a.txt" is current, and ":bn 2" is run
- **THEN** the window shows "c.txt"

#### Scenario: By number
- **WHEN** "a.txt" is buffer 1 and "b.txt" buffer 2 is current and ":b 1" is run
- **THEN** the window shows "a.txt"

### Requirement: Refusals of the buffer switch
When the current buffer is a modified file buffer, a switch SHALL be refused with "E37: No write since last change (add ! to override)" unless the bang is given, which keeps it hidden with its changes. A number of no listed file buffer SHALL report "E86: Buffer N does not exist", no listed file buffer at all "E85: There is no listed buffer", an argument to `:bn`, `:bp`, or `:bN` that is not a number "E488: Trailing characters: arg", and `:b name` "Not implemented: :buffer name".

#### Scenario: A missing number
- **WHEN** ":b 9" is run with two buffers
- **THEN** the message is "E86: Buffer 9 does not exist" and the window keeps its buffer

#### Scenario: Refused on a modified buffer
- **WHEN** "x" is pressed on "a.txt" with "b.txt" listed and ":bn" is run
- **THEN** the message is "E37: No write since last change (add ! to override)" and the window keeps "a.txt"

#### Scenario: Forced switch keeps the changes hidden
- **WHEN** "x" is pressed on "a.txt" with "b.txt" listed and ":bn!" is run
- **THEN** the window shows "b.txt" and ":ls" lists "a.txt" as hidden and modified

### Requirement: Deleting a buffer from the list
`:bd`, `:bdelete`, and `:bd N` SHALL remove the current buffer or buffer number N from the list and close every window showing it, a tab page closing with its last window, except that while the current window shows it and is the editor's last window, that window SHALL show the next listed file buffer after it, or the one before it when it was last; when no other listed file buffer exists, the current window SHALL show a new empty buffer with a new number instead.

#### Scenario: Delete the current buffer
- **WHEN** "a.txt" and "b.txt" are listed, "a.txt" is current in the only window, and ":bd" is run
- **THEN** the window shows "b.txt" and ":ls" lists only "b.txt"

#### Scenario: Delete the last buffer
- **WHEN** only "a.txt" is listed and ":bd" is run
- **THEN** the window shows an empty unnamed buffer numbered 2 and ":ls" lists only it

#### Scenario: Delete a hidden buffer by number
- **WHEN** "a.txt" is buffer 1, hidden, "b.txt" is current, and ":bd 1" is run
- **THEN** the window still shows "b.txt" and ":ls" lists only "b.txt"

#### Scenario: Delete closes the windows showing the buffer
- **WHEN** ":sp b.txt" is run, `<C-w>j` moves to "a.txt", and ":bd 2" is run
- **THEN** one window remains, showing "a.txt"

#### Scenario: Delete in a split closes the window
- **WHEN** ":sp b.txt" is run and ":bd" is run in the new window
- **THEN** one window remains, showing "a.txt"

### Requirement: Refusals of the buffer delete
A modified buffer SHALL be refused with "E89: No write since last change for buffer N (add ! to override)" unless the bang is given, which discards its changes. A number of no listed file buffer, and a plugin's scratch buffer, SHALL report "E516: No buffers were deleted: " followed by the command as typed; a name argument SHALL answer "Not implemented: :bdelete name".

#### Scenario: Refused on a modified buffer
- **WHEN** "x" is pressed on "a.txt" and ":bd" is run
- **THEN** the message is "E89: No write since last change for buffer 1 (add ! to override)" and "a.txt" stays listed

#### Scenario: A missing number
- **WHEN** ":bd 9" is run
- **THEN** the message is "E516: No buffers were deleted: bd 9"
