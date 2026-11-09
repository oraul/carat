## Purpose

The command palette: one list of every action and ex command with its key and description, filtered by typing, so a user finds and runs a command without knowing its key.

## ADDED Requirements

### Requirement: Leader p and F1 open the palette
With the default configuration, in normal mode, `<leader>p` and `<F1>` SHALL open the command palette: the command line shows the prompt `>` with an empty text, and a bordered float titled "Commands" over the editor lists every core action, every action of an enabled plugin, and every ex command, the first entry selected. Each row SHALL show the entry's name (an ex command as `:` and its full name), its first normal-mode key in Vim notation, or nothing when it has none, and its description.

#### Scenario: Open with the leader
- **WHEN** the default configuration is loaded on "a.txt" in a 24-row terminal and Space, "p" are typed
- **THEN** the message row starts with ">" and a float titled "Commands" shows rows with names, keys, and descriptions, such as "window.split", "<C-w>s", and "Split window"

#### Scenario: Open with F1
- **WHEN** `<F1>` is typed in normal mode
- **THEN** the palette opens as with `<leader>p`

#### Scenario: Ex commands are listed
- **WHEN** the palette is open and "nohl" is typed
- **THEN** the row of ":nohlsearch" shows with its description

### Requirement: Typing filters the list
Each character typed at the palette's prompt SHALL filter the list to the entries whose name or description holds the typed characters in order, ignoring ASCII case, and Backspace SHALL widen it again. A text no entry matches SHALL show an empty float reading "No match". The first entry SHALL be selected after every change of the text.

#### Scenario: Fuzzy match
- **WHEN** the palette is open and "wsp" is typed
- **THEN** the first row is "window.split"

#### Scenario: Description match
- **WHEN** the palette is open and "vertically" is typed
- **THEN** the rows of "window.vsplit" and ":vsplit" show

#### Scenario: Nothing matches
- **WHEN** "zzzzqx" is typed
- **THEN** the float reads "No match"

### Requirement: The best match comes first
The filtered list SHALL put a match of consecutive characters and of characters at the start of a word or a dotted segment first, a shorter text first on a tie, and equal matches in the table's order.

#### Scenario: Segment starts win
- **WHEN** the palette is open and "ws" is typed
- **THEN** "window.split" is listed before "window.vsplit"

### Requirement: Ctrl-N and Ctrl-P move the selection
While the palette is open, `<C-n>` SHALL select the next entry and `<C-p>` the previous one, stopping at the ends, and the float SHALL scroll to keep the selected row shown.

#### Scenario: Move down and up
- **WHEN** the palette is open, "split" is typed, and `<C-n>` is typed twice and `<C-p>` once
- **THEN** the second row is selected

### Requirement: Enter runs the selected entry
Enter SHALL close the palette and return to normal mode, then run the selected entry: an action as if its key had been pressed in normal mode (a motion moves, an operator waits for its motion), an ex command as if its full name had been typed after `:` and Enter, its message and error shown as such. Enter with no entry SHALL only close the palette.

#### Scenario: Run an action
- **WHEN** "a.txt" is shown, the palette is open, "wsp" is typed, and Enter is typed
- **THEN** no float shows, the mode is normal, and two windows show

#### Scenario: Run an ex command
- **WHEN** the buffer of "a.txt" is modified, the palette is open, ":write" is selected, and Enter is typed
- **THEN** "a.txt" holds the buffer's text

#### Scenario: An operator waits for its motion
- **WHEN** the palette is open, "operator.delete" is selected, Enter is typed, and then "j" is typed
- **THEN** two lines are deleted

### Requirement: Esc closes the palette
Esc at the palette's prompt SHALL close the float and return to normal mode with nothing run; `:` and the search keys typed while the palette is open SHALL be text of the prompt.

#### Scenario: Cancel
- **WHEN** the palette is open, "split" is typed, and Esc is typed
- **THEN** no float shows, the mode is normal, and one window shows

### Requirement: The palette costs nothing while closed
A key typed while the palette is closed SHALL allocate nothing more than before this capability.

#### Scenario: Benchmark held
- **WHEN** `make bench` runs the `lh` scenario
- **THEN** its allocations per key equal main's recorded figure
