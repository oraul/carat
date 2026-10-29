# Spec Delta

## MODIFIED Requirements

### Requirement: Write-all writes every modified buffer
:wa", ":wall", and their bang forms SHALL write every modified buffer in the list, in list order across every tab page, to its own path with the message of ":w", clear its modified flag, and show the message of the last write. An unmodified buffer and a scratch buffer owned by a plugin SHALL not be written nor reported. A modified buffer with no path SHALL report "E141: No file name for buffer N", N being its list position from 1; the other buffers SHALL still be written and the first failure SHALL be the message shown.

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
