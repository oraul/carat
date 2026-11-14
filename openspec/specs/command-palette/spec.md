# command-palette Specification

## Purpose
The command palette: one list of every action and ex command with its key and description, filtered by typing, so a user finds and runs a command without knowing its key.

## Requirements

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

### Requirement: A row fits its columns by display cells

Each palette row SHALL show the name in a 30-cell column, the description, and the first normal-mode key in a 12-cell column at the row's right end, a control key in caret notation (`^W` for `<C-w>`). A text wider than its column SHALL be cut at a character boundary, a combining mark kept with its character, and padded so each column starts at the same cell on every row; a description given under two cells is left out, the row is cut to the float's width, and no key width stops the editor.

#### Scenario: A key of wide characters

- **WHEN** `keymap.normal あいうえおかき window.split` is configured and the user presses `<Space>p` and types `window.split`
- **THEN** the palette shows the `window.split` row with the description starting at cell 30 and the key starting 12 cells before the row's end, cut to at most 11 cells, and the editor keeps running

#### Scenario: A key with combining marks

- **WHEN** a key of letters each followed by a combining accent is bound to `window.split` and the user opens the palette and types `window.split`
- **THEN** the key takes one cell per letter, keeps every accent with its letter, and starts 12 cells before the row's end

#### Scenario: A 29-character name is whole

- **WHEN** the user presses `<Space>p` and types `inner_single`
- **THEN** the row shows `textobject.inner_single_quote` whole, followed by a space and its description at cell 30

#### Scenario: The key in caret notation on the right

- **WHEN** the user presses `<Space>p` and types `window.split`
- **THEN** the `window.split` row reads the name, `Split window` from cell 30, and `^Ws` starting 12 cells before the row's end

#### Scenario: A narrow palette leaves the description out

- **WHEN** the screen is 46 columns wide under `option.winborder none`, so the palette's text is 42 columns, and the user presses `<Space>p` and types `window.split`
- **THEN** the `window.split` row reads the name, then `^Ws` from cell 30, without its description, and no cell of the row is drawn in `PmenuExtra` or `PmenuExtraSel`

### Requirement: Matched characters are marked

The palette SHALL draw the description column of each shown row in `PmenuExtra`, and in `PmenuExtraSel` on the selected row, and the characters the typed text matched in `PmenuMatch`, and in `PmenuMatchSel` on the selected row, in the field the match was scored in: the name when its score is at least the description's, otherwise the description. A matched character a column's cut hides SHALL not be drawn. With an empty text nothing SHALL be marked.

#### Scenario: A matched name's letters in PmenuMatch

- **WHEN** the user presses `<Space>p`, types `wsp`, and moves the selection off the `window.split` row
- **THEN** the `w`, `s`, and `p` of `window.split` on that row are drawn in `PmenuMatch` and its other name characters in `Pmenu`

#### Scenario: The selected row's match in PmenuMatchSel

- **WHEN** the user presses `<Space>p` and types `wsp`
- **THEN** on the selected `window.split` row the matched letters are drawn in `PmenuMatchSel`, its description in `PmenuExtraSel`, and its other name characters in `PmenuSel`

#### Scenario: A description match is marked in its column

- **WHEN** the user presses `<Space>p` and types `vertically`
- **THEN** the `window.vsplit` row draws the matched letters of its description in `PmenuMatch` or `PmenuMatchSel` and no character of its name in either
