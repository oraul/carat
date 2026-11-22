## MODIFIED Requirements

### Requirement: Edit opens a file or reloads the current one
":e path" and ":edit path" SHALL show the file in the current window: the listed buffer for that path, with the cursor where a window last left it, else the file read from disk, or an empty buffer if it does not exist,, the cursor at (0, 0). ":e" alone or with the buffer's own path SHALL reload the buffer in place. A modified buffer SHALL refuse it with E37 when `option.hidden` is off or it reloads, unless the bang discards the changes. The buffer left SHALL stay listed, hidden.

#### Scenario: Open another file
- **WHEN** ":e b.txt" is run on an unmodified buffer and "b.txt" holds "zz"
- **THEN** the buffer path is "b.txt", the lines are ["zz"], the cursor is at (0, 0), and the message is "\"b.txt\" 1L, 3B"

#### Scenario: Open a new file
- **WHEN** ":e new.txt" is run and the file does not exist
- **THEN** the buffer path is "new.txt", the lines are [""], and the message is "\"new.txt\" [New]"

#### Scenario: Refused while modified
- **WHEN** `option.hidden` is off and ":e b.txt" is run on a modified buffer
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

#### Scenario: Edit leaves a modified buffer hidden under hidden
- **WHEN** `option.hidden` is on and ":e b.txt" is run on a modified "a.txt"
- **THEN** the window shows "b.txt" and "a.txt" stays listed, hidden and modified; ":e" and ":e a.txt" on the modified buffer are still refused with E37
