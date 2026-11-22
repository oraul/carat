## MODIFIED Requirements

### Requirement: Flag options take Vim's boolean forms
`:se[t]` SHALL take the flags `number` (`nu`), `relativenumber` (`rnu`), `expandtab` (`et`), `autoindent` (`ai`), `list`, `hidden` (`hid`), `startscreen`, and `reducedmotion` in Vim's boolean forms: `name` turns it on, `noname` off, `invname` and `name!` switch it, and `name?` shows `  name` or `noname`. A value (`name=x`) SHALL be refused with `E474: Invalid argument: <argument>`, and a `no` or `inv` prefix or a trailing `!` on an option that is not a flag likewise.

#### Scenario: Turning a flag on, off, and over
- **WHEN** `:set nonu`, then `:set nu`, then `:set invnu`, then `:set nu!` are run
- **THEN** `:set nu?` shows `nonumber`, then `  number`, then `nonumber`, then `  number`

#### Scenario: A value for a flag
- **WHEN** `:set et=1` is run
- **THEN** the message row shows `E474: Invalid argument: et=1`

#### Scenario: A flag prefix on a number
- **WHEN** `:set nots` is run
- **THEN** the message row shows `E474: Invalid argument: nots`

#### Scenario: Set hidden changes the next switch
- **WHEN** `:set nohidden` is run, "x" is pressed on "a.txt" with "b.txt" listed, and ":bn" is run, then `:set hid` is run and ":bn" is run again
- **THEN** the first ":bn" is refused with E37 and the second shows "b.txt"
