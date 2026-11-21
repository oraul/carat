## ADDED Requirements

### Requirement: Tab completes an ex command name
At the `:` prompt, when the text before the cursor is only letters, `<Tab>` SHALL replace it with the first full ex command name it begins, in the precedence order of the registered commands, and `<S-Tab>` with the last; the empty line SHALL complete every name.

#### Scenario: Tab completes a command name
- **WHEN** ":", "v", "s", `<Tab>` are pressed
- **THEN** the bottom row shows ":vsplit"

#### Scenario: Many matches
- **WHEN** ":", "s", `<Tab>` are pressed
- **THEN** the bottom row shows the first command beginning with "s" and the popup lists every command beginning with "s"

#### Scenario: Cycling back
- **WHEN** ":", "v", "s", `<Tab>`, `<Tab>` are pressed
- **THEN** the bottom row shows ":vs" again, and a further `<S-Tab>` shows ":vsplit"

### Requirement: Tab completes a path after a file command
After `:e`, `:w`, `:sp`, `:vs`, or `:tabe` and blanks, `<Tab>` SHALL complete the path before the cursor from the entries of its directory, read through the file port relative to the working directory, a directory ending in `/`; a directory starting with `/`, `~/`, or `../` SHALL be read as typed, a dot file offered only for a typed name starting with a dot, and at most 1000 entries read per directory.

#### Scenario: A directory
- **WHEN** ":e li" then `<Tab>` are typed in a working directory holding the directory "lib"
- **THEN** the bottom row shows ":e lib/"

#### Scenario: A file
- **WHEN** ":e lib/" then `<Tab>` are typed and "lib" holds "a.rb"
- **THEN** the bottom row shows ":e lib/a.rb"

#### Scenario: A path with a space
- **WHEN** ":e my" then `<Tab>` are typed and the working directory holds "my notes.txt"
- **THEN** the bottom row shows ":e my notes.txt"

#### Scenario: A path outside the working directory as typed
- **WHEN** ":e ../" then `<Tab>` are typed
- **THEN** the matches are the entries of the working directory's parent

#### Scenario: The bounded directory read
- **WHEN** `<Tab>` completes in a directory of 1001 entries
- **THEN** the popup offers 1000 matches

#### Scenario: No match
- **WHEN** ":e zz" then `<Tab>` are typed and no entry begins with "zz"
- **THEN** the bottom row still shows ":e zz" and the popup reads "No matches  Esc close"

### Requirement: The completion menu shows above the command line
While completing, a bordered popup menu SHALL show the matches above the command line at the column of the completed word, its rows in `Pmenu`, the inserted match in `PmenuSel`, and the typed characters in `PmenuMatch`, at most 10 rows around the selection; text after the cursor SHALL be kept.

#### Scenario: The popup stands above the command line
- **WHEN** ":e lib/" then `<Tab>` are typed
- **THEN** a bordered float ends above the command line with its first row in `PmenuSel`

#### Scenario: Completing in the middle of the line
- **WHEN** ":vs", `<Home>`, `<Right>`, `<Right>`, `<Tab>` are pressed
- **THEN** the bottom row shows ":vsplits"

### Requirement: The completion menu closes before the line
A key that changes the command line or its cursor other than `<Tab>` and `<S-Tab>` SHALL close the menu and keep the line as shown; `<Esc>` with the menu open SHALL close it and stay on the command line, and a second `<Esc>` SHALL discard the line. `<Tab>` and `<S-Tab>` at the `/`, `?`, palette, and plugin prompts SHALL do nothing, and `<C-n>` and `<C-p>` SHALL keep moving the palette's selection.

#### Scenario: Escape closes the menu first
- **WHEN** ":e lib/", `<Tab>`, `<Esc>` are pressed
- **THEN** the mode is command-line, the bottom row shows ":e lib/a.rb", and no float shows; a second `<Esc>` returns to normal mode

#### Scenario: Typing closes the menu
- **WHEN** ":e lib/", `<Tab>`, "x" are pressed
- **THEN** the bottom row shows ":e lib/a.rbx" and no float shows

#### Scenario: Tab at another prompt does nothing
- **WHEN** "/", "a", `<Tab>` are pressed
- **THEN** the bottom row shows "/a" and no float shows
