# Spec Delta

## Purpose

The operators and commands of visual mode act on the selection of the current kind, charwise, linewise, or blockwise, store what they remove or copy in the registers, and leave the cursor and the mode where Neovim leaves them.

## ADDED Requirements

### Requirement: d, x, and Delete remove the selection
"d", "x", and "<Del>" SHALL delete the selection into the register with its kind and return to normal mode: charwise leaves the cursor at the start, linewise on the first non-blank of the line now at the top row, blockwise at the block's top-left character.

#### Scenario: Charwise delete
- **WHEN** "vld" is pressed at (0, 1) of "abcd"
- **THEN** the line is "ad", the cursor is at (0, 1), and the mode is normal

#### Scenario: Linewise delete
- **WHEN** "Vjd" is pressed on row 0 of ["a", "b", "  c"]
- **THEN** the lines are ["  c"] and the cursor is at (0, 2)

#### Scenario: Blockwise delete
- **WHEN** "<C-v>jlx" is pressed at (0, 1) of ["abcd", "efgh"]
- **THEN** the lines are ["ad", "eh"], the cursor is at (0, 1), and the register holds the block "bc\nfg"

### Requirement: y copies the selection
"y" SHALL copy the selection into the register with its kind, return to normal mode, and put the cursor at the start: the earlier end for charwise, the top-left character for blockwise, and for linewise column 0 of the top row when the anchor is on it, else the cursor's own position.

#### Scenario: Charwise yank backward
- **WHEN** "vhy" is pressed at (0, 2) of "abcd"
- **THEN** the register holds "bc" and the cursor is at (0, 1)

#### Scenario: Linewise yank from the anchor
- **WHEN** "Vjy" is pressed at (0, 2) of ["abcd", "efgh"]
- **THEN** the register holds the lines "abcd" and "efgh" and the cursor is at (0, 0)

#### Scenario: Linewise yank with the cursor on top
- **WHEN** "Vky" is pressed at (1, 2) of ["abcd", "efgh"]
- **THEN** the cursor is at (0, 2)

### Requirement: c and s change the selection
"c" and "s" SHALL delete the selection into the register and enter insert mode: charwise at the start, linewise on one line keeping the top row's indent with autoindent, blockwise at the block's top-left with the typed text inserted on every other row of the block that reaches it when insert mode is left.

#### Scenario: Charwise change
- **WHEN** "vlc" is pressed at (0, 1) of "abcd"
- **THEN** the line is "ad", the cursor is at (0, 1), and the mode is insert

#### Scenario: Linewise change keeps the indent
- **WHEN** "Vjc" is pressed on row 0 of ["  a", "b", "c"]
- **THEN** the lines are ["  ", "c"] and the cursor is at (0, 2)

#### Scenario: Block change
- **WHEN** "<C-v>jlcX<Esc>" is pressed at (0, 1) of ["abcd", "efgh"]
- **THEN** the lines are ["aXd", "eXh"] and the cursor is at (0, 1)

### Requirement: Shift by the count
">" and "<" SHALL shift the selected lines right or left by count times shiftwidth and put the cursor on the first non-blank of the top row; in blockwise they SHALL insert or remove that many spaces at the block's left edge on every row that reaches it, leaving the cursor at the block's top-left.

#### Scenario: Linewise indent with a count
- **WHEN** "Vj2>" is pressed on row 0 of ["a", "b"] with shiftwidth 2
- **THEN** the lines are ["    a", "    b"] and the cursor is at (0, 4)

#### Scenario: Dedent
- **WHEN** "v<" is pressed on "    a"
- **THEN** the line is "  a"

#### Scenario: Block indent
- **WHEN** "<C-v>j>" is pressed at (0, 1) of ["ab", "cd"]
- **THEN** the lines are ["a  b", "c  d"] and the cursor is at (0, 1)

### Requirement: J and gJ join the selected lines
"J" SHALL join the selected lines, at least two, as normal-mode "J" does, and "gJ" SHALL join them without inserting or removing blanks; the cursor goes where the last join happened.

#### Scenario: Join three lines
- **WHEN** "VjjJ" is pressed on row 0 of ["a", "b", "c"]
- **THEN** the lines are ["a b c"]

#### Scenario: Join one selected line with the next
- **WHEN** "vJ" is pressed on row 0 of ["a", "  b"]
- **THEN** the lines are ["a b"]

#### Scenario: gJ keeps the blanks
- **WHEN** "VgJ" is pressed on row 0 of ["a", "  b"]
- **THEN** the lines are ["a  b"] and the cursor is at (0, 1)

### Requirement: p and P replace the selection with a register
"p" and "P" SHALL replace the selection with the register's text count times, read before the selection is removed; "p" SHALL store the removed text in the unnamed register and "P" SHALL leave every register unchanged.

#### Scenario: p swaps the unnamed register
- **WHEN** "yiwwviwp" is pressed at (0, 0) of "one two"
- **THEN** the line is "one one" and the unnamed register holds "two"

#### Scenario: P keeps the register
- **WHEN** "yiwwviwP" is pressed at (0, 0) of "one two"
- **THEN** the line is "one one" and the unnamed register holds "one"

#### Scenario: Empty register
- **WHEN** "vp" is pressed with nothing in the unnamed register
- **THEN** the message is "E353: Nothing in register \"", the mode is normal, and the buffer is unchanged

### Requirement: Putting a register of another kind into a selection
A linewise register put into a charwise selection SHALL split the line there and put its lines between the halves; any register put into a linewise selection SHALL become whole lines; a one-line charwise register put into a block SHALL be put on every row of the block; a linewise register put into a block SHALL go below it for "p" and above it for "P".

#### Scenario: Lines into a charwise selection
- **WHEN** "yyjlvp" is pressed on row 0 of ["ab", "cd"]
- **THEN** the lines are ["ab", "c", "ab", ""] and the cursor is at (2, 0)

#### Scenario: Text into a linewise selection
- **WHEN** "yljVp" is pressed at (0, 0) of ["a", "b"]
- **THEN** the lines are ["a", "a"]

#### Scenario: Text into a block
- **WHEN** "yl" at (0, 0), then "l<C-v>jp" are pressed on ["xab", "ycd"]
- **THEN** the lines are ["xxb", "yxd"]

### Requirement: r replaces every selected character
"r" followed by a printable character SHALL replace every selected character, not the line breaks, with it and return to normal mode with the cursor at the start of the selection; a key that is not printable SHALL cancel and stay in visual mode.

#### Scenario: Charwise replace
- **WHEN** "vlrx" is pressed at (0, 0) of "abc"
- **THEN** the line is "xxc" and the cursor is at (0, 0)

#### Scenario: Block replace
- **WHEN** "<C-v>jrx" is pressed at (0, 1) of ["ab", "cd"]
- **THEN** the lines are ["ax", "cx"]

### Requirement: ~, u, and U change the case of the selection
"~" SHALL toggle, "u" lower, and "U" upper the case of every selected character and return to normal mode with the cursor at the start of the selection.

#### Scenario: Toggle case
- **WHEN** "v$~" is pressed at (0, 0) of "aB"
- **THEN** the line is "Ab" and the cursor is at (0, 0)

#### Scenario: Upper case of lines
- **WHEN** "VjU" is pressed on row 0 of ["ab", "cd"]
- **THEN** the lines are ["AB", "CD"]

#### Scenario: Lower case of a block
- **WHEN** "<C-v>jlu" is pressed at (0, 0) of ["ABC", "DEF"]
- **THEN** the lines are ["abC", "deF"]

### Requirement: Uppercase keys act on whole lines
"X" and "D" SHALL delete, "Y" SHALL yank, and "C", "S", and "R" SHALL change the selected lines as whole lines in charwise and linewise visual mode. In blockwise mode "X" and "Y" SHALL act on the block, "D" and "C" on the block extended to the end of every row, and "S" and "R" on whole lines.

#### Scenario: X deletes the lines
- **WHEN** "vX" is pressed at (0, 1) of ["ab", "cd"]
- **THEN** the lines are ["cd"]

#### Scenario: D in a block deletes to the end
- **WHEN** "<C-v>jD" is pressed at (0, 1) of ["abc", "def"]
- **THEN** the lines are ["a", "d"]

#### Scenario: X in a block deletes the block
- **WHEN** "<C-v>jX" is pressed at (0, 1) of ["abc", "def"]
- **THEN** the lines are ["ac", "df"]

#### Scenario: C in a block changes to the end
- **WHEN** "<C-v>jCX<Esc>" is pressed at (0, 1) of ["abc", "def"]
- **THEN** the lines are ["aX", "dX"]

#### Scenario: Y yanks lines
- **WHEN** "vY" is pressed at (0, 1) of ["ab", "cd"]
- **THEN** the unnamed register holds the line "ab"

### Requirement: I and A in a block insert on every row
In blockwise mode "I" SHALL enter insert mode before the block and "A" after it on the top row; leaving insert mode with text typed on that row and no line added SHALL insert the same text on every other row of the block, skipping rows that end before the block for "I", padding them with spaces for "A", and after "$" appending at every row's end. The cursor then goes to the block's top-left.

#### Scenario: Block insert
- **WHEN** "<C-v>jjIX<Esc>" is pressed at (0, 1) of ["ab", "", "cd"]
- **THEN** the lines are ["aXb", "", "cXd"] and the cursor is at (0, 1)

#### Scenario: Block append pads short rows
- **WHEN** "<C-v>jllAX<Esc>" is pressed at (0, 0) of ["a", "abc"]
- **THEN** the lines are ["a  X", "abcX"]

#### Scenario: Append after $
- **WHEN** "<C-v>j$AX<Esc>" is pressed at (0, 0) of ["ab", "c"]
- **THEN** the lines are ["abX", "cX"]

### Requirement: I and A in charwise and linewise mode
In charwise and linewise visual mode "I" SHALL enter insert mode at the start of the selection's top row as a linewise operand starts, and "A" after the last character of the bottom row.

#### Scenario: Linewise insert
- **WHEN** "VjIX<Esc>" is pressed at (0, 1) of ["ab", "cd"]
- **THEN** the lines are ["Xab", "cd"]

#### Scenario: Charwise append
- **WHEN** "vjAX<Esc>" is pressed at (0, 0) of ["ab", "cd"]
- **THEN** the lines are ["ab", "cdX"]
