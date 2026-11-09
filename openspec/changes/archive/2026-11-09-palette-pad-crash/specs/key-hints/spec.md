## ADDED Requirements

### Requirement: A hint row is cut by display cells

Each hint row SHALL be cut at a character boundary to at most the float's width in terminal cells, so text of wide characters never reaches past the float's box, and a combining mark SHALL stay with the character before it.

#### Scenario: A remap of wide characters

- **WHEN** `<leader>xa` is remapped to a text of fifty wide characters on an 80-column screen and the user waits after `<Space>x`
- **THEN** the hints float shows the `a` row cut to at most 78 cells, its box no wider than 78 cells, and the editor keeps running
