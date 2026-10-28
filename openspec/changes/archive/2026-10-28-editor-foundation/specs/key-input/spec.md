# Spec Delta

## Purpose

Key input turns the bytes a terminal sends into key codes the editor can bind, and defines the Vim key notation that configuration files use to name keys. One code represents one key press so the rest of the editor never sees escape sequences.

## ADDED Requirements

### Requirement: Printable characters decode to their code point
A UTF-8 encoded printable character arriving from the terminal SHALL decode to one key whose code is its Unicode code point, including multi-byte characters.

#### Scenario: ASCII letter
- **WHEN** the byte for "a" arrives
- **THEN** one key with code 97 is produced

#### Scenario: Multi-byte character
- **WHEN** the UTF-8 bytes for "é" arrive in one read
- **THEN** one key with code 233 is produced

#### Scenario: Multi-byte character split across reads
- **WHEN** the first byte of "é" arrives in one read and the second in the next
- **THEN** no key is produced after the first read and one key with code 233 after the second

### Requirement: Control keys decode to their byte
A control byte SHALL decode to a key whose code is the byte value, so Enter is 13, Tab is 9, Backspace is 127 or 8, and Ctrl plus a letter is the letter's position in the alphabet.

#### Scenario: Enter and Ctrl-C
- **WHEN** the bytes 13 and 3 arrive
- **THEN** the keys 13 and 3 are produced, in that order

### Requirement: Escape sequences decode to special keys
The sequences terminals send for the arrow keys, Home, End, Insert, Delete, Page Up, Page Down, and F1 to F12, in both the CSI form and the SS3 form, SHALL decode to one key each with a code above the Unicode range. A modifier parameter in a CSI sequence SHALL be accepted and ignored.

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

### Requirement: A lone Escape is the Escape key after a short wait
An Escape byte that is not followed by more bytes within the escape timeout SHALL decode to the Escape key, code 27, so that pressing Escape alone is recognized without a terminator.

#### Scenario: Escape alone
- **WHEN** the byte 27 arrives and the escape timeout passes with no further bytes
- **THEN** the key 27 is produced

#### Scenario: Escape followed by a sequence in the next read
- **WHEN** the byte 27 arrives and the bytes "[A" arrive before the escape timeout
- **THEN** only the key Up is produced

### Requirement: Alt plus a key decodes as an Alt-flagged key
An Escape byte immediately followed by a printable character in the same read SHALL decode to that character's code with the Alt flag bit set.

#### Scenario: Alt-x
- **WHEN** the bytes 27 and "x" arrive in one read
- **THEN** one key is produced whose code is 120 with the Alt flag set

### Requirement: Vim key notation names every key
The editor SHALL parse key notation into key codes and format key codes back into notation. Plain characters stand for themselves; the named keys are <CR>, <Esc>, <Tab>, <BS>, <Space>, <Del>, <Up>, <Down>, <Left>, <Right>, <Home>, <End>, <PageUp>, <PageDown>, <Insert>, <F1> to <F12>, <lt>, and <Bar>; <C-x> is Ctrl plus a key, <A-x> and <M-x> are Alt plus a key, and <leader> expands to the configured leader. Names are case-insensitive.

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
