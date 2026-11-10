## MODIFIED Requirements

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
