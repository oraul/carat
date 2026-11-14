## MODIFIED Requirements

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

## ADDED Requirements

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
