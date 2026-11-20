## MODIFIED Requirements

### Requirement: Wrong flags are refused
`c` and `l` SHALL report Not implemented and change nothing, the string a later `&`, `:&`, or `:s` reuses included. Any other text after the flags and count SHALL report "E488: Trailing characters: " with that text, and a count of 0 "E939: Positive count required".

#### Scenario: Trailing characters
- **WHEN** ":s/a/b/gx" is run
- **THEN** the message is "E488: Trailing characters: x"

#### Scenario: Confirm
- **WHEN** ":s/a/b/c" is run
- **THEN** the message is "Not implemented: :s flag c" and the text is unchanged

#### Scenario: A refused flag keeps the last string
- **WHEN** ":s/a/b/" is run on the first of two lines holding "a", then "j", ":s/a/z/c", and "&"
- **THEN** both lines hold "b"

#### Scenario: The list flag is refused
- **WHEN** ":s/a/b/" is run on the first of two lines holding "a", then "j", ":s/a/z/l", and ":&&"
- **THEN** both lines hold "b"

### Requirement: A substitute is one undo step and sets the last search
A substitute SHALL be one undo step, SHALL not be repeated by ".", and SHALL leave the cursor on the first non-blank character of the last line it changed. Its pattern SHALL become the last search pattern that "n" repeats and highlights, the "/" register, and a search history entry. "n" and "N" SHALL match that pattern with the case the options give, as a typed search does, whatever case the `i` or `I` flag gave the substitute.

#### Scenario: One undo step
- **WHEN** ":%s/a/b/" is run on three lines holding "a" and "u" is typed
- **THEN** every line holds "a" again

#### Scenario: n repeats the pattern
- **WHEN** ":s/b/x/" is run on "abc b" and "n" is typed
- **THEN** the cursor is on the "b" at column 4

#### Scenario: n after the i flag matches case by the options
- **WHEN** ":s/A/x/i" is run on "abc a A" with 'ignorecase' off and "n" is typed
- **THEN** the cursor is on the "A" at column 6

#### Scenario: N after the I flag ignores case by the options
- **WHEN** ":s/a/x/I" is run on "a A b" with 'ignorecase' on and "N" is typed
- **THEN** the cursor is on the "A" at column 2
