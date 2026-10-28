# text-objects Specification

## Purpose
Text objects select the text around the cursor for an operator: a word, a WORD, a sentence, a paragraph, the inside or whole of a bracket pair, or the inside or whole of a quoted string, in the inner and "a" forms Vim uses.

## Requirements

### Requirement: Word objects
In operator-pending mode "iw" SHALL select the word under the cursor, or the run of blanks under it, and "aw" SHALL select the word plus the blanks after it, or the blanks before it when none follow. "iW" and "aW" SHALL do the same with WORDs. A count SHALL extend the selection over that many words and blank runs on the line. Both are charwise.

#### Scenario: diw and daw in the middle of a line
- **WHEN** "diw" is pressed at (0, 5) of "one two three", and separately "daw"
- **THEN** the line is "one  three" after "diw" and "one three" after "daw"

#### Scenario: aw at the end of a line takes the blanks before
- **WHEN** "daw" is pressed at (0, 5) of "one two"
- **THEN** the line is "one"

#### Scenario: iw on blanks
- **WHEN** "diw" is pressed at (0, 2) of "a   b"
- **THEN** the line is "ab"

#### Scenario: Counted word objects
- **WHEN** "d2iw" is pressed at (0, 0) of "one two three", and separately "d2aw"
- **THEN** the line is "two three" after "d2iw" and "three" after "d2aw"

#### Scenario: WORD objects
- **WHEN** "diW" is pressed at (0, 1) of "foo.bar baz", and separately "daW"
- **THEN** the line is " baz" after "diW" and "baz" after "daW"

### Requirement: Sentence objects
"is" SHALL select the sentence under the cursor without the blanks after it, and "as" SHALL include them. Both are charwise.

#### Scenario: dis and das
- **WHEN** "dis" is pressed at (0, 6) of "One. Two. Three.", and separately "das"
- **THEN** the line is "One.  Three." after "dis" and "One. Three." after "das"

### Requirement: Paragraph objects
"ip" SHALL select the lines of the paragraph under the cursor, or the run of empty lines under it, and "ap" SHALL include the empty lines after the paragraph, or the ones before it when none follow. Both are linewise.

#### Scenario: dip and dap
- **WHEN** "dip" is pressed on row 0 of ["a", "b", "", "c"], and separately "dap"
- **THEN** the lines are ["", "c"] after "dip" and ["c"] after "dap"

#### Scenario: dap on the last paragraph
- **WHEN** "dap" is pressed on row 2 of ["a", "", "b", "c"]
- **THEN** the lines are ["a"]

### Requirement: Bracket objects
For the pairs "()", "[]", "{}", and "<>", "i" followed by either bracket or by "b" for "()" and "B" for "{}" SHALL select the text inside the innermost enclosing pair, and "a" SHALL include the brackets. A count SHALL select the count-th enclosing pair. The pair MAY span lines; when both brackets stand alone at the ends of their lines the inner object SHALL be the lines between them. With no enclosing pair nothing SHALL happen.

#### Scenario: Inner and whole parentheses
- **WHEN** "di(" is pressed at (0, 6) of "f(a, (b), c)", and separately "da("
- **THEN** the line is "f(a, (), c)" after "di(" and "f(a, , c)" after "da("

#### Scenario: Counted and aliased parentheses
- **WHEN** "2di)" is pressed at (0, 6) of "f(a, (b), c)", and separately "dib"
- **THEN** the line is "f()" after "2di)" and "f(a, (), c)" after "dib"

#### Scenario: Cursor on the bracket itself
- **WHEN** "di(" is pressed at (0, 5) of "f(a, (b), c)"
- **THEN** the line is "f(a, (), c)"

#### Scenario: Square, curly, and angle brackets
- **WHEN** "di[" is pressed at (0, 2) of "x[1][2]", "daB" at (0, 2) of "{ a }", and "di<" at (0, 1) of "<a>"
- **THEN** the lines are "x[][2]", "", and "<>"

#### Scenario: Inner block over lines
- **WHEN** "di{" is pressed at (1, 2) of ["f {", "  a", "  b", "}"]
- **THEN** the lines are ["f {", "}"]

#### Scenario: No enclosing pair
- **WHEN** "di(" is pressed at (0, 1) of "abc"
- **THEN** the line is unchanged and the mode is normal

### Requirement: Quote objects
For the double quote, the single quote, and the backtick, "i" followed by the quote SHALL select the text inside the quoted string on the cursor line that contains the cursor, or the first one after the cursor, and "a" SHALL include the quotes and the blanks after them, or the blanks before them when none follow. A quote preceded by a backslash SHALL not count. With no quoted string nothing SHALL happen.

#### Scenario: Inside and around a string
- **WHEN** "di\"" is pressed at (0, 6) of "say \"hi there\" now", and separately "da\""
- **THEN** the line is "say \"\" now" after "di\"" and "say now" after "da\""

#### Scenario: Cursor before the string
- **WHEN** "di'" is pressed at (0, 0) of "say 'hi' now"
- **THEN** the line is "say '' now"

#### Scenario: Escaped quote is skipped
- **WHEN** "di\"" is pressed at (0, 3) of "a \"b\\\"c\" d"
- **THEN** the line is "a \"\" d"

#### Scenario: Backtick
- **WHEN** "di`" is pressed at (0, 1) of "`ab`"
- **THEN** the line is "``"
