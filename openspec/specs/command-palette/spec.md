# command-palette Specification

## Purpose
The command palette: one list of every action and ex command with its key and description, filtered by typing, so a user finds and runs a command without knowing its key.

## Requirements

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

### Requirement: Typing filters the list
Each character typed at the palette's prompt SHALL filter the list to the entries whose name or description holds the typed characters in order, the first of them (and the first after each `_` typed) starting a word or a dotted segment, ignoring ASCII case and a leading `:`, as the completion popup filters; Backspace SHALL widen it again. A text no entry matches SHALL show an empty float reading "No match". The first entry SHALL be selected after every change of the text.

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
The filtered list SHALL put an entry whose name or description starts with the typed text first, then one matching more typed characters consecutively, then the shorter text, and equal matches in the table's order.

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

### Requirement: Matched characters are marked

The palette SHALL draw the name column of each shown row in `PmenuExtra`, and in `PmenuExtraSel` on the selected row, and the characters the typed text matched in `PmenuMatch`, and in `PmenuMatchSel` on the selected row, in the field the match was scored in: the name when its score is at least the description's, otherwise the description. A matched character a column's cut hides SHALL not be drawn. With an empty text nothing SHALL be marked.

#### Scenario: A matched name's letters in PmenuMatch

- **WHEN** the user presses `<Space>p`, types `wsp`, and moves the selection off the `window.split` row
- **THEN** the `w`, `s`, and `p` of `window.split` on that row are drawn in `PmenuMatch`, its other name characters in `PmenuExtra`, and its description in `Pmenu`

#### Scenario: The selected row's match in PmenuMatchSel

- **WHEN** the user presses `<Space>p` and types `wsp`
- **THEN** on the selected `window.split` row the matched letters are drawn in `PmenuMatchSel`, its other name characters in `PmenuExtraSel`, and its description in `PmenuSel`

#### Scenario: A description match is marked in its column

- **WHEN** the user presses `<Space>p` and types `vertically`
- **THEN** the `window.vsplit` row draws the matched letters of its description in `PmenuMatch` or `PmenuMatchSel` and no character of its name in either

### Requirement: A row leads with its label and fits its columns by display cells

Each palette row SHALL show, from the left, the entry's description, its readable label, then its name in a 30-cell column, then its first normal-mode key in a 12-cell column at the row's right end, a control key in caret notation (`^W` for `<C-w>`). Each column SHALL start at the same cell on every row. Under 20 description cells the name SHALL be left out, under 12 the key too, so every row shows its label. No key width SHALL stop the editor.

#### Scenario: A key of wide characters

- **WHEN** `keymap.normal あいうえおかき window.split` is configured and the user presses `<Space>p` and types `window.split`
- **THEN** the palette shows the `window.split` row with the name starting 42 cells and the key 12 cells before the row's end, the key cut to at most 11 cells ending in `…`, and the editor keeps running

#### Scenario: A key with combining marks

- **WHEN** a key of letters each followed by a combining accent is bound to `window.split` and the user opens the palette and types `window.split`
- **THEN** the key takes one cell per letter, keeps every accent with its letter, and starts 12 cells before the row's end

#### Scenario: A 29-character name is whole

- **WHEN** the user presses `<Space>p` and types `inner_single`
- **THEN** the row shows `textobject.inner_single_quote` whole from 42 cells before the row's end, followed by a space

#### Scenario: The label first, the key in caret notation on the right

- **WHEN** the user presses `<Space>p` and types `window.split`
- **THEN** the `window.split` row reads `Split window` from cell 0, the name from 42 cells before the row's end, and `^Ws` starting 12 cells before the row's end

#### Scenario: A narrow palette leaves the name out

- **WHEN** the screen is 46 columns wide under `option.winborder none`, so the palette's text is 42 columns, and the user presses `<Space>p` and types `window.split`
- **THEN** the `window.split` row reads `Split window` from cell 0 and `^Ws` from 30 cells, without the name, and no cell of the row is drawn in `PmenuExtra` or `PmenuExtraSel`

#### Scenario: A palette at the smallest screen shows a label

- **WHEN** the screen is 8 columns wide, the narrowest the palette opens at, under the default border or `option.winborder none`, or the palette's text is under 24 columns, and the user presses `<Space>p` and types `window.split`
- **THEN** the `window.split` row starts with the first characters of `Split window` from cell 0 and shows no key, while at 24 columns of text and wider the key `^Ws` starts 12 cells before the row's end

### Requirement: A cut text is marked

A text wider than its palette column SHALL be cut at a character boundary, a combining mark kept with its character, its last shown cell `…`, or `>` under `option.icons ascii`, so the cut shows.

#### Scenario: A cut description is marked

- **WHEN** the screen is 80 columns wide and the user presses `<Space>p` and types `completion`, so a description longer than its column shows
- **THEN** that description is cut at a character boundary, its last shown cell is `…`, and its name still starts 42 cells before the row's end

#### Scenario: An ascii cut mark

- **WHEN** `option.icons ascii` is configured and a description longer than its column shows
- **THEN** its last shown cell is `>`
