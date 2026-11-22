## ADDED Requirements

### Requirement: The hidden option decides whether a switch leaves a modified buffer
The global option `hidden` (`hid`), a flag read from the `option.hidden` line and set by `:set`, SHALL be on by default. When it is on, `:e` of another file and every buffer switch (`:b`, `:bn`, `:bp`, `:bN`, `:bfirst`, `:blast`, Ctrl-^, `gt`, `gT`) SHALL leave a modified file buffer hidden with its changes; when it is off they SHALL refuse it with E37 unless the bang is given. ":qa" SHALL still name a hidden modified buffer with E37 and E162.

#### Scenario: A hidden modified buffer is named when quitting
- **WHEN** `option.hidden` is on, "x" is pressed on "a.txt", ":e b.txt" is run, and ":qa" is run
- **THEN** the editor stays, the message is "E37: No write since last change" and "E162: No write since last change for buffer "a.txt"" on two lines, and the window shows "a.txt"

#### Scenario: Hidden is on by default
- **WHEN** no configuration line sets `option.hidden`
- **THEN** the option is on

## MODIFIED Requirements

### Requirement: Refusals of the buffer switch
With `option.hidden` off, a switch from a modified file buffer SHALL be refused with "E37: No write since last change (add ! to override)" unless the bang is given, which keeps it hidden with its changes. A number of no listed file buffer SHALL report "E86: Buffer N does not exist", no listed file buffer at all "E85: There is no listed buffer", an argument to `:bn`, `:bp`, or `:bN` that is not a number "E488: Trailing characters: arg", and `:b name` "Not implemented: :buffer name".

#### Scenario: A missing number
- **WHEN** ":b 9" is run with two buffers
- **THEN** the message is "E86: Buffer 9 does not exist" and the window keeps its buffer

#### Scenario: Refused on a modified buffer
- **WHEN** `option.hidden` is off, "x" is pressed on "a.txt" with "b.txt" listed and ":bn" is run
- **THEN** the message is "E37: No write since last change (add ! to override)" and the window keeps "a.txt"

#### Scenario: Forced switch keeps the changes hidden
- **WHEN** "x" is pressed on "a.txt" with "b.txt" listed and ":bn!" is run
- **THEN** the window shows "b.txt" and ":ls" lists "a.txt" as hidden and modified

#### Scenario: A modified buffer is left hidden under hidden
- **WHEN** `option.hidden` is on, "x" is pressed on "a.txt" with "b.txt" listed, and ":bn", ":bp", ":bN", or ":b 2" is run
- **THEN** the window shows the other buffer with no message and ":ls" lists "a.txt" as hidden and modified

### Requirement: Moving to the first and the last buffer
`:bf`, `:bfirst`, `:br`, and `:brewind` SHALL show the first listed file buffer in the current window, and `:bl` and `:blast` the last one, with the rules of the buffer switch (a modified buffer left hidden under `option.hidden`, E37 without the bang when it is off, E85 with no listed file buffer); showing the buffer already shown SHALL change nothing.

#### Scenario: First and last
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed in that order, "b.txt" is current, and ":bfirst" is run
- **THEN** the window shows "a.txt", and ":blast" then shows "c.txt"

#### Scenario: Rewind is first
- **WHEN** "a.txt" and "b.txt" are listed and "b.txt" is current and ":br" is run
- **THEN** the window shows "a.txt"

#### Scenario: First refused on a modified buffer
- **WHEN** `option.hidden` is off, "x" is pressed on "b.txt" with "a.txt" listed first and ":bfirst" is run
- **THEN** the message is "E37: No write since last change (add ! to override)" and the window keeps "b.txt"

#### Scenario: First and last leave a modified buffer hidden
- **WHEN** `option.hidden` is on, "x" is pressed on "b.txt" with "a.txt" listed first, and ":bfirst" is run, then "x" is pressed and ":blast" is run
- **THEN** the window shows "a.txt", then "b.txt", with no message
