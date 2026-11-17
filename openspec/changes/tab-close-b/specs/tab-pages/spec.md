## MODIFIED Requirements

### Requirement: Opening a tab page
":tabnew" SHALL open a new tab page after the current one with one window showing a new empty buffer with no name and make it current; ":tabe file" and ":tabedit file" SHALL do the same showing the file, opened as ":e file" does, a file already listed showing its buffer with no empty buffer left listed; ":tabe" and ":tabedit" without a file SHALL behave as ":tabnew".

#### Scenario: Tab new
- **WHEN** ":tabnew" is run while "a.txt" is shown
- **THEN** there are two tab pages, the second is current, its window shows an unnamed empty buffer, and the first still shows "a.txt"

#### Scenario: Tab edit a file
- **WHEN** ":tabe b.txt" is run and "b.txt" holds "zz"
- **THEN** the new tab page is current and its window shows ["zz"] for "b.txt"

#### Scenario: Tab edit without a file
- **WHEN** ":tabedit" is run
- **THEN** the new tab page shows an unnamed empty buffer

#### Scenario: New tab after the current one
- **WHEN** three tab pages exist, the first is current, and ":tabnew" is run
- **THEN** the new tab page is the second of four and is current

#### Scenario: Tab edit a listed file leaves no empty buffer
- **WHEN** ":e alpha.txt", ":e beta.txt", and ":tabe alpha.txt" are run
- **THEN** the second tab page shows "alpha.txt", and the top row and ":ls" list "alpha.txt" and "beta.txt" only
