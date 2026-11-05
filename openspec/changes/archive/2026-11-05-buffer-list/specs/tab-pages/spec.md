## MODIFIED Requirements

### Requirement: Closing tab pages
":tabc" and ":tabclose" SHALL close the current tab page and make the one before it current, or the first when the first was closed; on the last tab page the message SHALL be "E784: Cannot close last tab page". ":tabo" and ":tabonly" SHALL close every other tab page; with one tab page the message SHALL be "Already only one tab page". A file buffer shown only in a closed tab page SHALL stay hidden in the buffer list, with its changes.

#### Scenario: Tab close
- **WHEN** ":tabnew" then ":tabclose" are run
- **THEN** one tab page remains and it shows "a.txt"

#### Scenario: Close the first of three
- **WHEN** three tab pages exist, the first is current, and ":tabc" is run
- **THEN** two remain and the first of them is current

#### Scenario: Last tab page
- **WHEN** ":tabclose" is run with one tab page
- **THEN** the message is "E784: Cannot close last tab page"

#### Scenario: Tab only
- **WHEN** ":tabnew" is run twice and ":tabonly" is run
- **THEN** one tab page remains, the one that was current

#### Scenario: Already only one tab page
- **WHEN** ":tabo" is run with one tab page
- **THEN** the message is "Already only one tab page"

#### Scenario: Hidden buffer after tab close
- **WHEN** ":tabe b.txt" is run, "x" is pressed, ":tabclose" is run, and ":qa" is run
- **THEN** the editor stays, the message is "E37: No write since last change" and "E162: No write since last change for buffer "b.txt"" on two lines, and the window shows "b.txt"

