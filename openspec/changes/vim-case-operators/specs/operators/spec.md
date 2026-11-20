## ADDED Requirements

### Requirement: Case operators
"g~", "gu", and "gU" SHALL switch, lower, and upper the case of the characters of the operand, a motion, a text object, or count lines of the doubled form ("g~~" or "g~g~", "guu" or "gugu", "gUU" or "gUgU"), writing no register. After a charwise operand the cursor SHALL be at the start of the range; after a linewise one on the first line of the range at the column of its start. A count before the operator and one before the operand SHALL multiply.

#### Scenario: g~ gu gU over motions
- **WHEN** "g~w", "gUw", or "guw" is pressed at the start of a word, and "gU$", "gu0", "gUb", "gUj", "gUk", "gUG", "gUgg", and "g~}" over a motion in the other directions
- **THEN** exactly the characters the motion covers change case, the cursor is at the start of the range, and no register changes

#### Scenario: g~ gu gU over text objects
- **WHEN** "g~iw", "guaw", "gUi(", "gUa(", "gUi\"", "gUip", or "gUis" is pressed inside the object
- **THEN** the characters of the object change case and the cursor is at its start

#### Scenario: g~ gu gU with counts
- **WHEN** "2gUw", "gU2w", "2gU2w", "2gUl", or "9gUl" is pressed
- **THEN** the counts multiply, and a count past the end of the line stops at the line end

#### Scenario: the doubled forms
- **WHEN** "g~~", "guu", "gUU", "g~g~", "gugu", "gUgU", "3gUU", "gU2U", or "9guu" is pressed, or "gUd" or "g~" then Escape
- **THEN** the lines the count names change case with the cursor where it was on the first of them, a count past the last line stops there, and the last two do nothing

#### Scenario: the edges of the buffer
- **WHEN** "gUU" is pressed on an empty line, in an empty buffer, on a line ending in blanks, on the last line with no final newline, or in a file with CRLF line ends, or "gUl", "gUh", or "gUj" cannot move
- **THEN** the buffer holds the text with its blanks and last line kept, nothing changes where nothing can, and the mode is normal

### Requirement: Case of a letter
Each letter SHALL change by itself as Neovim's simple case mapping has it: "ß" stays under "g~" and "gu" and becomes "SS" under "gU", "İ" becomes "i" when lowered, and a letter with no single-letter case form stays.

#### Scenario: multibyte letters
- **WHEN** "g~~", "gUU", "guu", "gUiw", "gUl", or "gUe" is pressed over accented, Greek, or Cyrillic letters, "ß", a ligature, a final sigma, or "İ"
- **THEN** each letter changes as in Neovim, columns count characters, and a "ß" under "gU" becomes "SS"

### Requirement: Repeating and undoing a case operator
The dot command SHALL repeat each case operator, and one "u" SHALL undo each. An operand that changes no character SHALL leave the buffer and its undo history as they were.

#### Scenario: dot repeats a case operator
- **WHEN** a case operator is pressed, the cursor moved, and "." pressed, also with a new count, after a doubled form, and after a visual "gU", "~", or "gu"
- **THEN** the same operation runs over the same kind of operand at the cursor, a new count replacing the old

#### Scenario: one undo for a case operator
- **WHEN** a case operator over several lines, a paragraph, or multibyte letters is pressed, then "u"; and "." then "u"
- **THEN** the text and the cursor are as before the operator, and "u" after the repeat undoes only the repeat

### Requirement: Case operators in the visual modes
In a visual mode "g~", "gu", and "gU" SHALL act on the selection at once, as "~", "u", and "U" do, and leave the visual mode with the cursor at the start of the selection.

#### Scenario: the visual modes
- **WHEN** "gU", "g~", or "gu" is pressed in characterwise, linewise, or blockwise visual mode, and "~", "u", or "U" over multibyte letters
- **THEN** the selected characters, lines, or block change case, the mode is normal, and the cursor is at the start of the selection
