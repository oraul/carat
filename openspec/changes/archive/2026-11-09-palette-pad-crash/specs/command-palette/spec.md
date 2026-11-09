## ADDED Requirements

### Requirement: A row fits its columns by display cells

Each palette row SHALL lay out the name, the key, and the description in columns measured in terminal cells: a name or key wider than its column SHALL be cut at a character boundary, keeping a combining mark with the character before it, and padded with spaces so the next column starts at the same cell on every row, and the whole row SHALL be cut to the float's width in cells. A bound key of any width SHALL never stop the editor.

#### Scenario: A key of wide characters

- **WHEN** `keymap.normal あいうえおかき window.split` is configured and the user presses `<Space>p` and types `window.split`
- **THEN** the palette shows the `window.split` row with the key cut to at most 11 cells, the description starting at cell 40, and the editor keeps running

#### Scenario: A key with combining marks

- **WHEN** a key of letters each followed by a combining accent is bound to `window.split` and the user opens the palette and types `window.split`
- **THEN** the key takes one cell per letter, keeps every accent with its letter, and the description starts at cell 40
