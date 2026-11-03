## ADDED Requirements

### Requirement: A byte outside a well-formed UTF-8 sequence is one replacement cell
Text SHALL be decoded as UTF-8 per RFC 3629, and every byte outside a well-formed sequence (an overlong form, a surrogate, a sequence above U+10FFFF, a truncated sequence, or a lone continuation byte) SHALL be one character of its own, displayed as one U+FFFD cell. No code point above U+10FFFF or from U+D800 to U+DFFF SHALL reach the terminal.

#### Scenario: Hostile sequences decode to replacement characters
- **WHEN** the bytes C0 AF, E0 80 80, ED A0 80, F0 80 80 80, F4 90 80 80, F5 80, E4 B8, and 80 are each decoded
- **THEN** each byte is one character of U+FFFD, one cell wide

#### Scenario: Well-formed sequences at the edges
- **WHEN** the bytes C2 80, E0 A0 80, ED 9F BF, EE 80 80, F0 90 80 80, and F4 8F BF BF are each decoded
- **THEN** each is one character, U+0080, U+0800, U+D7FF, U+E000, U+10000, and U+10FFFF

#### Scenario: A cell beyond Unicode is written as the replacement character
- **WHEN** a frame cell holds the code 0x110000 or 0xD800 and the frame is presented
- **THEN** the bytes written hold U+FFFD for that cell and the presenter raises nothing
