## ADDED Requirements

### Requirement: showtabline is 0, 1, or 2
`option.showtabline` SHALL take 0, 1, or 2, Neovim's values: 0 never shows the tab row, 1 shows it only with two or more tab pages or files, 2 always shows it. The shipped configuration SHALL set 2. A value outside 0 to 2, or a word, SHALL be reported as `file:line: option.showtabline takes a number from 0 to 2` (a word as `takes a number`) and leave the value before it.

#### Scenario: The shipped default
- **WHEN** the editor starts with the shipped defaults
- **THEN** `showtabline` is 2 and nothing is reported

#### Scenario: A value from a line
- **WHEN** the project file holds "option.showtabline 0", or "option.showtabline 2"
- **THEN** the option takes that value and nothing is reported

#### Scenario: A value out of range
- **WHEN** the project file holds "option.showtabline 0" and then "option.showtabline 3" on line 2
- **THEN** ".caratrc:2: option.showtabline takes a number from 0 to 2" is reported and the option stays 0

### Requirement: :set answers showtabline as not implemented
`:set showtabline=N` and `:set stal=N` SHALL be answered `Not implemented: :set <argument>` until `:set` handles numeric options, never `E518`.

#### Scenario: :set answers not implemented
- **WHEN** ":set showtabline=2" or ":set stal=0" is run
- **THEN** the message row shows `Not implemented: :set showtabline=2` or `Not implemented: :set stal=0`
