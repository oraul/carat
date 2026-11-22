## MODIFIED Requirements

### Requirement: The filetype and syntax are set with set
`:se[t]` SHALL accept `filetype=<name>` or `ft=<name>`, setting the current buffer's filetype and syntax, and `syntax=<name>` or `syn=<name>`, setting its syntax alone (`OFF` for none, `ON` for its filetype); `<option>?` and the bare name SHALL show `  filetype=<name>` or `  syntax=<name>`. `theme` and `background` (`bg`) SHALL answer `Not implemented: :set <argument>`, an unknown name `E518: Unknown option: <name>`.

#### Scenario: Setting the filetype
- **WHEN** `:set ft=ruby` is run in a buffer of `notes.txt` holding `def go`
- **THEN** `def` is drawn in the Define group

#### Scenario: Asking for the filetype
- **WHEN** `:set ft?` is run in a buffer of `a.rb`
- **THEN** the message row shows `  filetype=ruby`

#### Scenario: Turning one buffer's syntax off
- **WHEN** `:set syntax=OFF` is run in a buffer of `a.rb`
- **THEN** that buffer is drawn in the normal group and `:set syntax?` shows `  syntax=`

#### Scenario: An option set does not handle yet
- **WHEN** `:set theme=carat-light` or `:set bg=terminal` is run
- **THEN** the message row shows `Not implemented: :set theme=carat-light` or `Not implemented: :set bg=terminal`

#### Scenario: An unknown option
- **WHEN** `:set bogus` is run
- **THEN** the message row shows `E518: Unknown option: bogus`
