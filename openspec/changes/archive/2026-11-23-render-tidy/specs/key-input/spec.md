## ADDED Requirements

### Requirement: Bracketed paste decodes to text
The text between the bracketed paste marks (`ESC [ 200 ~` and `ESC [ 201 ~`) SHALL decode to text codes, each flagged as pasted, and never to keys: a printable character, including a multi-byte one and an illegal byte as U+FFFD, is its code point; a tab is a tab; a carriage return, a line feed, or both is one newline; every other control byte, Escape included, is dropped. A paste cut short by a read SHALL wait for the rest, and a lone Escape inside it SHALL NOT become the Escape key.

#### Scenario: Escape and colon in a paste are text
- **WHEN** the bytes of a paste holding "a", Escape, ":w!" arrive
- **THEN** the codes produced are flagged as pasted, the Escape is dropped, and none is the Escape key

#### Scenario: A paste split across reads
- **WHEN** a paste arrives in reads cut inside the start mark, inside a character, and inside the end mark
- **THEN** its text decodes whole and the keys after the end mark decode as keys

#### Scenario: Newlines in a paste
- **WHEN** a paste holds a line feed, a carriage return, and a CRLF
- **THEN** each is one pasted newline

### Requirement: Pasted text is inserted, never run
A pasted code SHALL NOT be looked up in a keymap. Insert mode SHALL insert it as text, a pasted newline breaking the line; the command line SHALL take its printable characters and drop a newline; no other mode SHALL do anything with it.

#### Scenario: A paste in insert mode runs nothing
- **WHEN** a paste holding an Escape and ":w!" arrives in insert mode
- **THEN** the editor stays in insert mode and the colon and the text after it are in the buffer

#### Scenario: A paste in normal mode runs nothing
- **WHEN** a paste holding "dd:q!" and a newline arrives in normal mode
- **THEN** the buffer is unchanged, no command line opens, and the editor does not quit
