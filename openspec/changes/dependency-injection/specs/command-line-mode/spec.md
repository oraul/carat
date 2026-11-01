## ADDED Requirements

### Requirement: Ex command names are recognized from their abbreviation to their full name
Every ex command SHALL be recognized when typed as its abbreviation, its full name, or any spelling between them that starts the full name, as Vim's notation name[suffix] means; a shorter spelling or one that does not start the full name SHALL report E492. When two commands accept the typed name, the first in the registered order SHALL run.

#### Scenario: Vertical split abbreviated
- **WHEN** ":vsp" is run in a window of 24 rows and 80 columns
- **THEN** the window is split vertically as ":vsplit" splits it

#### Scenario: Write abbreviated between its forms
- **WHEN** the buffer "a.txt" is modified and ":wr" is run
- **THEN** the buffer is written as ":write" writes it

#### Scenario: Write-all and exit abbreviated
- **WHEN** ":wal" is run over a modified buffer, and later ":xi" over a clean one
- **THEN** ":wal" writes as ":wall" does and ":xi" leaves the editor as ":xit" does

#### Scenario: Tab page commands abbreviated
- **WHEN** three tab pages are open, the third is current, and ":tabfirs" is run
- **THEN** the first tab page is current

#### Scenario: Too short or not a prefix
- **WHEN** ":tabf" or ":vsplitx" is run
- **THEN** the message is "E492: Not an editor command: tabf" or "E492: Not an editor command: vsplitx"
