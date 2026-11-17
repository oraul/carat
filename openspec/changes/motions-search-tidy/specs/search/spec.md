## ADDED Requirements

### Requirement: incsearch keeps the cursor on a character

While a pattern is typed with "incsearch" on, the cursor SHALL rest on the first match clamped to the last character of the match's line, as Enter then places it, so a match at the end of a line never leaves the cursor past the line's last character.

#### Scenario: incsearch on a match at the line end

- **WHEN** "/", "$" are pressed on ["abc"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 2

### Requirement: Tilde, a second caret, and a collection holding the delimiter read as in Neovim

`~` in a "/" or "?" pattern SHALL match the replacement string of the last substitute, and report "E33: No previous substitute regular expression" only when no substitute has run. A `^` right after an anchoring `^` SHALL match a literal caret. A collection SHALL end at the `]` the compiler ends it at, a `]` first in it or after a backslash being a member, so a delimiter inside a collection never ends the typed pattern.

#### Scenario: Tilde after a substitute

- **WHEN** ":s/a/xy/" was run on ["a", "b xy"] and "/", "~", Enter are pressed with the cursor at row 0, column 0
- **THEN** the cursor is at row 1, column 2

#### Scenario: Tilde with no substitute

- **WHEN** "/", "~", Enter are pressed on ["a"]
- **THEN** the message is the error "E33: No previous substitute regular expression"

#### Scenario: A second caret is literal

- **WHEN** "/", "^", "^", Enter are pressed on ["^a", "b", "^c"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 2, column 0

#### Scenario: An escaped bracket in a collection

- **WHEN** "/", "[", "\", "]", "/", "]", Enter are pressed on ["a", "x/"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 1, column 1
