## MODIFIED Requirements

### Requirement: Escape sequences decode to special keys
The sequences terminals send for the arrow keys, Home, End, Insert, Delete, Page Up, Page Down, and F1 to F12, in both the CSI form and the SS3 form, SHALL decode to one key each with a code above the Unicode range. A modifier parameter in a CSI sequence SHALL be accepted and ignored, except that Page Up and Page Down with a modifier that holds Ctrl SHALL decode to the keys Ctrl-PageUp and Ctrl-PageDown, which key notation names `<C-PageUp>` and `<C-PageDown>`.

#### Scenario: Arrow keys
- **WHEN** the bytes of ESC [ A, ESC [ B, ESC [ C, and ESC [ D arrive
- **THEN** the keys Up, Down, Right, and Left are produced

#### Scenario: Tilde-terminated keys
- **WHEN** the bytes of ESC [ 3 ~ and ESC [ 5 ~ arrive
- **THEN** the keys Delete and Page Up are produced

#### Scenario: SS3 form
- **WHEN** the bytes of ESC O H arrive
- **THEN** the key Home is produced

#### Scenario: Modified arrow
- **WHEN** the bytes of ESC [ 1 ; 5 C arrive
- **THEN** the key Right is produced

#### Scenario: Ctrl-PageDown and Ctrl-PageUp decode to their own keys
- **WHEN** the bytes of ESC [ 6 ; 5 ~ and ESC [ 5 ; 5 ~ arrive
- **THEN** the keys Ctrl-PageDown and Ctrl-PageUp are produced, and "<C-PageDown><C-PageUp>" in notation gives the same codes and formats back to the same names
