## MODIFIED Requirements

### Requirement: Leader p and F1 open the palette
With the default configuration, in normal mode, `<leader>p` and `<F1>` SHALL open the command palette: a bordered float titled `Commands N/M` (N matching, M listed) whose first row is the query, `> ` and the typed text, where the cursor stands, the command-line row blank, then a row for every core action, enabled plugin action, and ex command, the first selected. A row SHALL show the entry's name (an ex command with its `:`), its first normal-mode key, or nothing, and its description.

#### Scenario: Open with the leader
- **WHEN** the default configuration is loaded on "a.txt" in a 24-row terminal and Space, "p" are typed
- **THEN** the message row is blank, a float titled "Commands" has `> ` on its first row, the cursor after it, and shows rows with names, keys, and descriptions, such as "window.split", "<C-w>s", and "Split window"

#### Scenario: The query is the float's first row (the palette)
- **WHEN** the palette is open and "wsp" is typed, then Left and "x"
- **THEN** the float's first row reads `> wsp`, then `> wsxp`, the cursor stands in that row after the text before the command line's cursor, the message row is blank, and the title reads `Commands N/M` with the matches and the entries

#### Scenario: A screen with no room for a list row
- **WHEN** the screen has too few rows for the float's query row and a list row and the palette is opened
- **THEN** no float shows and the prompt `> ` and the typed text stand on the command-line row

#### Scenario: Open with F1
- **WHEN** `<F1>` is typed in normal mode
- **THEN** the palette opens as with `<leader>p`

#### Scenario: Ex commands are listed
- **WHEN** the palette is open and "nohl" is typed
- **THEN** the row of ":nohlsearch" shows with its description
