## MODIFIED Requirements

### Requirement: Escape sequences decode to special keys
The sequences terminals send for the arrow keys, Home, End, Insert, Delete, Page Up, Page Down, and F1 to F12, in both the CSI form and the SS3 form, SHALL decode to one key each with a code above the Unicode range. A modifier parameter in a CSI sequence SHALL be accepted and ignored, except for Ctrl on Page Up and Page Down, which decode to the keys Ctrl-PageUp and Ctrl-PageDown (`<C-PageUp>` and `<C-PageDown>`), and for Ctrl or Shift on Left and Right.

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
- **WHEN** the bytes of ESC [ 1 ; 3 C arrive
- **THEN** the key Right is produced

#### Scenario: Ctrl-PageDown and Ctrl-PageUp decode to their own keys
- **WHEN** the bytes of ESC [ 6 ; 5 ~ and ESC [ 5 ; 5 ~ arrive
- **THEN** the keys Ctrl-PageDown and Ctrl-PageUp are produced, and "<C-PageDown><C-PageUp>" in notation gives the same codes and formats back to the same names

### Requirement: Vim key notation names every key
The editor SHALL parse key notation into key codes and format key codes back into notation. Plain characters stand for themselves; the named keys are <CR>, <Esc>, <Tab>, <BS>, <Space>, <Del>, <Up>, <Down>, <Left>, <Right>, <S-Left>, <S-Right>, <C-Left>, <C-Right>, <Home>, <End>, <PageUp>, <PageDown>, <Insert>, <F1> to <F12>, <lt>, and <Bar>; <C-x> is Ctrl plus a key, <A-x> and <M-x> are Alt plus a key, and <leader> expands to the configured leader. Names are case-insensitive.

#### Scenario: Sequence with named keys
- **WHEN** the notation ":w<CR>" is parsed
- **THEN** the codes are 58, 119, 13

#### Scenario: Control and Alt keys
- **WHEN** "<C-r>" and "<A-x>" are parsed
- **THEN** the codes are 18 and 120 with the Alt flag

#### Scenario: Leader expands
- **WHEN** "<leader>w" is parsed with the leader " "
- **THEN** the codes are 32, 119

#### Scenario: Round trip
- **WHEN** each code of the keys Up, 13, 27, 3, and 97 is formatted
- **THEN** the results are "<Up>", "<CR>", "<Esc>", "<C-c>", and "a"

#### Scenario: Malformed notation is an error
- **WHEN** the notation "<Nope>" is parsed
- **THEN** parsing reports an error naming the unknown key instead of producing codes

## ADDED Requirements

### Requirement: Ctrl and Shift arrows are their own keys
Left and Right with a modifier that holds Ctrl, or Shift without Ctrl, SHALL decode to the keys Ctrl-Left, Ctrl-Right, Shift-Left, and Shift-Right. A key of these four that a mode does not bind SHALL act as the plain Left or Right the mode binds.

#### Scenario: Ctrl and Shift arrows decode to their own keys
- **WHEN** the bytes of ESC [ 1 ; 5 D, ESC [ 1 ; 5 C, ESC [ 1 ; 2 D, and ESC [ 1 ; 2 C arrive
- **THEN** the keys Ctrl-Left, Ctrl-Right, Shift-Left, and Shift-Right are produced, and their notation gives the same codes and formats back to the same names

#### Scenario: An unbound Ctrl or Shift arrow acts as the plain arrow
- **WHEN** Ctrl-Right is typed in normal mode
- **THEN** the cursor moves one character right, as Right does
