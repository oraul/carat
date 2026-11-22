## MODIFIED Requirements

### Requirement: Ctrl-^ shows the alternate buffer
Ctrl-^, and Ctrl-6, which terminals send as the same key, SHALL show the window's alternate buffer as `:b N` does, recording the position left and making the buffer left the alternate one; with a count it SHALL show the buffer of that number. Without an alternate buffer it SHALL answer `E23: No alternate file`, and a modified current file buffer SHALL refuse it with `E37` when `option.hidden` is off.

#### Scenario: Ctrl-^ goes back and forth
- **WHEN** line 3 of `a.txt` was left by `:e b.txt` and Ctrl-^ is typed twice
- **THEN** the first shows `a.txt` on line 3 and the second `b.txt`

#### Scenario: Ctrl-6 is Ctrl-^
- **WHEN** `:e b.txt` left `a.txt` and Ctrl-6 is typed
- **THEN** the window shows `a.txt`

#### Scenario: A count goes to that buffer
- **WHEN** three buffers are listed and `3` Ctrl-^ is typed in buffer 1
- **THEN** the window shows buffer 3

#### Scenario: No alternate buffer
- **WHEN** only one file was opened and Ctrl-^ is typed
- **THEN** the message is `E23: No alternate file` and the buffer stays

#### Scenario: A modified buffer refuses Ctrl-^
- **WHEN** `option.hidden` is off, `b.txt` was modified after leaving `a.txt`, and Ctrl-^ is typed
- **THEN** the message is `E37` and `b.txt` stays

#### Scenario: A modified buffer is left hidden by Ctrl-^
- **WHEN** `option.hidden` is on, `b.txt` was modified after leaving `a.txt`, and Ctrl-^ is typed
- **THEN** the window shows `a.txt` with no message and `b.txt` stays listed, hidden and modified
