## MODIFIED Requirements

### Requirement: Closing a window keeps a modified buffer hidden
When the window closed was the last one showing a file buffer, the buffer SHALL stay in the buffer list, hidden, with its changes, so that ":qa" refuses a modified one with E37 and E162 and ":wa" writes it; it SHALL stay listed after the write, and an unmodified one SHALL stay listed too, until ":bd" deletes it. A plugin's scratch buffer SHALL leave the list when its last window closes.

#### Scenario: Hidden modified buffer blocks quit-all
- **WHEN** ":sp b.txt" is run, "x" is pressed in the new window, `<C-w>c` closes it, and ":qa" is run
- **THEN** the editor stays and the message is "E37: No write since last change" and "E162: No write since last change for buffer "b.txt"" on two lines

#### Scenario: Write-all writes the hidden buffer
- **WHEN** after that ":wa" is run
- **THEN** "b.txt" holds the edited text, it is still listed, and ":qa" then ends the editor

#### Scenario: Hidden buffer comes back
- **WHEN** after hiding the modified "b.txt" ":e b.txt" is run
- **THEN** the window shows the edited lines and the buffer is still modified

#### Scenario: A clean buffer stays listed
- **WHEN** ":sp b.txt" is run and `<C-w>c` closes the new window without an edit
- **THEN** "b.txt" is still listed, hidden
