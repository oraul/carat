## MODIFIED Requirements

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
