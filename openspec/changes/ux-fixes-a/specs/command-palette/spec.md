## ADDED Requirements

### Requirement: A row leads with its label and fits its columns by display cells

Each palette row SHALL show, from the left, the entry's description, its readable label, then its name in a 30-cell column, then its first normal-mode key in a 12-cell column at the row's right end, a control key in caret notation (`^W` for `<C-w>`). Each column SHALL start at the same cell on every row. When the description would get under 20 cells the name SHALL be left out. No key width SHALL stop the editor.

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

### Requirement: A cut text is marked

A text wider than its palette column SHALL be cut at a character boundary, a combining mark kept with its character, its last shown cell `…`, or `>` under `option.icons ascii`, so the cut shows.

#### Scenario: A cut description is marked

- **WHEN** the screen is 80 columns wide and the user presses `<Space>p` and types `completion`, so a description longer than its column shows
- **THEN** that description is cut at a character boundary, its last shown cell is `…`, and its name still starts 42 cells before the row's end

#### Scenario: An ascii cut mark

- **WHEN** `option.icons ascii` is configured and a description longer than its column shows
- **THEN** its last shown cell is `>`

## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: A row fits its columns by display cells
**Reason**: the row led with the internal action name and cut the description with no mark (ux-pass finding 10).
**Migration**: none; the row keeps its three columns, the label now first (requirement "A row leads with its label and fits its columns by display cells").
