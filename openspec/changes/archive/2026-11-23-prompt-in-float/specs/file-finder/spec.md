## MODIFIED Requirements

### Requirement: Space f f and Ctrl-P open the finder
In normal mode `<leader>ff` and `<C-p>` SHALL open the finder: a bordered float titled `Files N/M` (N matching, M listed) SHALL show the query on its first row, the prompt `> ` and the typed text, where the cursor stands as a bar while the command-line row stays blank, and SHALL list the project's files below the working directory on the rows after it, the first highlighted with a leading `▎ `. The keys SHALL be default bindings of the plugin, which the configuration may replace.

#### Scenario: Space f f opens the finder
- **WHEN** the user presses `<Space>ff` in a project with three files
- **THEN** the mode is command-line, the float's first row reads `> `, the message row is blank, and the float titled `Files 3/3` lists the three paths after it, the first marked `▎ `

#### Scenario: Ctrl-P opens the finder
- **WHEN** the user presses `<C-p>` in normal mode
- **THEN** the finder opens as with `<Space>ff`

## ADDED Requirements

### Requirement: Every picker shows its query in its list float
The file, grep, buffer, and recent files pickers SHALL each show the typed text on the first row of their list float, the prompt `> ` then the text, with the cursor after the text before the command line's cursor in that row and the command-line row blank, the list on the rows after it, the highlight on its row of the list. Enter with no match SHALL open the prompt again on the same text with the cursor in the float. Closing the picker SHALL leave no float and no attachment.

#### Scenario: The query is the list float's first row (the finder)
- **WHEN** `<Space>ff` and "be" are typed, then Left and "x"
- **THEN** the float's first row reads `> be`, then `> bxe`, the cursor is in that row after the text before the command line's cursor, the message row is blank, and the title reads `Files 1/3`

#### Scenario: The query row is above the highlight
- **WHEN** `<Space>ff` and `<C-n>` are typed
- **THEN** the second file is the highlighted row, the third of the float, the query row being the first

#### Scenario: Enter with no match keeps the query in the float
- **WHEN** "zzz" and Enter are typed at the finder's prompt
- **THEN** the mode is command-line, the float's first row reads `> zzz`, and the cursor is in it after the text

#### Scenario: The prompt leaves the float when the finder closes
- **WHEN** the finder is open and Esc is typed
- **THEN** no float remains, the mode is normal, and the prompt is no longer attached to a float
