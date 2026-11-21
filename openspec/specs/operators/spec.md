# operators Specification

## Purpose
Operators change the text an operand selects: delete, change, yank, and shift over a motion, a text object, or a doubled operator, plus the standalone editing commands that stand for an operator with a fixed motion. Each leaves the cursor and the mode where Vim leaves them.

## Requirements

### Requirement: Delete
"d" SHALL remove the selected text and store it in the register. After a charwise delete the cursor SHALL be at the start of the range, clamped to the line; after a linewise delete it SHALL be on the first non-blank of the line that took the place of the first deleted line, or the last line when the buffer became shorter. Deleting every line SHALL leave one empty line.

#### Scenario: d$ and d0
- **WHEN** "d$" is pressed at (0, 1) of "abc", and separately "d0" at (0, 2)
- **THEN** the line is "a" with the cursor at (0, 0) after "d$", and "c" with the cursor at (0, 0) after "d0"

#### Scenario: dd goes to the first non-blank
- **WHEN** "dd" is pressed on row 0 of ["a", "  b"]
- **THEN** the lines are ["  b"] and the cursor is at (0, 2)

#### Scenario: dd on the last line
- **WHEN** "dd" is pressed on row 1 of ["a", "b"]
- **THEN** the lines are ["a"] and the cursor is at (0, 0)

#### Scenario: dd on the only line
- **WHEN** "dd" is pressed on "abc"
- **THEN** the lines are [""] and the cursor is at (0, 0)

#### Scenario: dG and dgg
- **WHEN** "dG" is pressed on row 1 of ["a", "b", "c"], and separately "dgg"
- **THEN** the lines are ["a"] after "dG" and ["c"] after "dgg"

#### Scenario: dl at the last character
- **WHEN** "dl" is pressed at (0, 2) of "abc"
- **THEN** the line is "ab" and the cursor is at (0, 1)

#### Scenario: Motions that cannot move delete nothing
- **WHEN** "dh" is pressed at (0, 0) of "abc", and "dj" on the last line of ["a", "b"]
- **THEN** nothing changes in either case and the mode is normal

### Requirement: Change
"c" SHALL delete the selected text, store it in the register, and enter insert mode at the start of the range. A linewise change SHALL replace the lines with one line holding the indent of the first line when autoindent is on and nothing otherwise, with the cursor after it. "cw" and "cW" on a non-blank character SHALL change to the end of the word, as "ce" and "cE".

#### Scenario: cw changes the word only
- **WHEN** "cw" is pressed at (0, 0) of "one two"
- **THEN** the line is " two", the cursor is at (0, 0), and the mode is insert

#### Scenario: cw on blanks
- **WHEN** "cw" is pressed at (0, 1) of "a  b"
- **THEN** the line is "ab", the cursor is at (0, 1), and the mode is insert

#### Scenario: cc keeps the indent with autoindent
- **WHEN** "cc" is pressed on row 0 of ["  ab", "c"] with autoindent on
- **THEN** the lines are ["  ", "c"], the cursor is at (0, 2), and the mode is insert

#### Scenario: cc without autoindent
- **WHEN** "2cc" is pressed on row 0 of ["  ab", "c", "d"] with autoindent off
- **THEN** the lines are ["", "d"], the cursor is at (0, 0), and the mode is insert

#### Scenario: c$ and ciw
- **WHEN** "c$" is pressed at (0, 1) of "abc", and separately "ciw" at (0, 5) of "one two three"
- **THEN** the line is "a" with the cursor at (0, 1) in insert mode after "c$", and "one  three" with the cursor at (0, 4) in insert mode after "ciw"

### Requirement: Yank
"y" SHALL store the selected text in the register without changing the buffer and move the cursor to the start of the range. A doubled "yy" SHALL leave the cursor where it was; a linewise yank over a backward motion SHALL move the cursor to the first yanked line keeping the wanted column.

#### Scenario: yw leaves the cursor and yb moves it
- **WHEN** "yw" is pressed at (0, 0) of "one two", and separately "yb" at (0, 4)
- **THEN** the buffer is unchanged, the cursor is at (0, 0) in both cases, and the register holds "one " both times

#### Scenario: yy and yk
- **WHEN** "yy" is pressed at (1, 1) of ["ab", "cd"], and separately "yk"
- **THEN** the cursor is at (1, 1) after "yy" and at (0, 1) after "yk"

### Requirement: Shift
">" SHALL indent the selected lines by shiftwidth and "<" SHALL dedent them, never below column 0, using spaces when expandtab is on and tabs filled with spaces otherwise. ">" SHALL leave empty lines empty. The cursor SHALL go to the first non-blank of the first shifted line. A doubled ">>" or "<<" SHALL shift count lines.

#### Scenario: Indent and dedent
- **WHEN** ">>" is pressed on "ab" with shiftwidth 2 and expandtab on, then "<<" twice
- **THEN** the line is "  ab" with the cursor at (0, 2), then "ab" with the cursor at (0, 0), then still "ab"

#### Scenario: Counted and motion shifts
- **WHEN** "3>>" is pressed on row 0 of ["a", "b", "c", "d"], and separately ">j"
- **THEN** the lines are ["  a", "  b", "  c", "d"] after "3>>" and ["  a", "  b", "c", "d"] after ">j"

#### Scenario: Empty lines stay empty
- **WHEN** "2>>" is pressed on row 0 of ["", "a"]
- **THEN** the lines are ["", "  a"]

#### Scenario: Tabs without expandtab
- **WHEN** ">>" is pressed on "ab" with shiftwidth 4, tabstop 8, and expandtab off, then ">>" again
- **THEN** the line is "    ab", then "\tab"

### Requirement: Standalone delete and change commands
"x" SHALL delete count characters under and after the cursor within the line, "s" SHALL do the same and enter insert mode, "S" SHALL act as "cc", "C" as "c$", "D" as "d$", and "Y" SHALL yank to the end of the line. Each SHALL accept a count as the motion it stands for does.

#### Scenario: x in the middle and at the end
- **WHEN** "x" is pressed at (0, 1) of "abc", and separately at (0, 2)
- **THEN** the line is "ac" with the cursor at (0, 1), and "ab" with the cursor at (0, 1)

#### Scenario: Counted x stops at the line end
- **WHEN** "3x" is pressed at (0, 1) of "abcd"
- **THEN** the line is "a" and the cursor is at (0, 0)

#### Scenario: x on an empty line
- **WHEN** "x" is pressed on an empty line
- **THEN** nothing changes

#### Scenario: s and S
- **WHEN** "2s" is pressed at (0, 1) of "abc", and separately "S" on row 0 of ["  ab", "c"] with autoindent on
- **THEN** the line is "a" with the cursor at (0, 1) in insert mode after "2s", and the lines are ["  ", "c"] with the cursor at (0, 2) in insert mode after "S"

#### Scenario: C and D with counts
- **WHEN** "2C" is pressed at (0, 1) of ["abc", "de", "f"], and separately "2D"
- **THEN** the lines are ["a", "f"] with the cursor at (0, 1) in insert mode after "2C", and ["a", "f"] with the cursor at (0, 0) in normal mode after "2D"

#### Scenario: Y then p
- **WHEN** "Y" then "p" are pressed at (0, 1) of "abc"
- **THEN** the line is "abbcc" and the cursor is at (0, 3)

### Requirement: Join
"J" SHALL join count lines, at least two, into one: the leading blanks of each joined line are removed and one space is inserted unless the line so far ends in a blank or the joined line is empty or starts with ")". The cursor SHALL be placed where the last line was joined. On the last line nothing SHALL happen; a count past the end SHALL join the lines that exist.

#### Scenario: J inserts one space
- **WHEN** "J" is pressed on row 0 of ["ab", "  cd"]
- **THEN** the lines are ["ab cd"] and the cursor is at (0, 2)

#### Scenario: Counted J
- **WHEN** "3J" is pressed on row 0 of ["a", "b", "c"]
- **THEN** the lines are ["a b c"] and the cursor is at (0, 3)

#### Scenario: No space before a closing parenthesis or after a blank
- **WHEN** "J" is pressed on row 0 of ["f(", ")"], and separately on ["ab ", "cd"]
- **THEN** the lines are ["f()"] with the cursor at (0, 2), and ["ab cd"] with the cursor at (0, 3)

#### Scenario: J on the last line
- **WHEN** "J" is pressed on row 1 of ["a", "b"]
- **THEN** nothing changes

### Requirement: Put
"p" SHALL insert the register text after the cursor and "P" before it, count times. Charwise text goes into the line, with the cursor on the last inserted character when it is one line and on the first inserted character otherwise; linewise text goes on new lines below or above, with the cursor on the first non-blank of the first new line. An empty register SHALL show the message "E353: Nothing in register" followed by the register name and change nothing.

#### Scenario: Charwise p and P
- **WHEN** "yw" is pressed at (0, 0) of "ab cd", then "p", and separately "yw" then "P"
- **THEN** the line is "aab b cd" with the cursor at (0, 3) after "p", and "ab ab cd" with the cursor at (0, 2) after "P"

#### Scenario: Counted charwise put
- **WHEN** "yl" then "3p" are pressed at (0, 0) of "ab"
- **THEN** the line is "aaaab" and the cursor is at (0, 3)

#### Scenario: Linewise p and P
- **WHEN** "yy" is pressed on row 0 of ["  a", "b"], then "p", and separately "yy" then "P"
- **THEN** the lines are ["  a", "  a", "b"] with the cursor at (1, 2) after "p", and ["  a", "  a", "b"] with the cursor at (0, 2) after "P"

#### Scenario: Counted linewise put
- **WHEN** "yy" then "2p" are pressed on row 0 of ["a", "b"]
- **THEN** the lines are ["a", "a", "a", "b"]

#### Scenario: Multi-line charwise put
- **WHEN** "de" is pressed at (0, 1) of ["ab", "cd"], then "p"
- **THEN** the lines are ["ab", "cd"] and the cursor is at (0, 1)

#### Scenario: Empty register
- **WHEN** "p" is pressed before anything was yanked or deleted
- **THEN** the message row shows "E353: Nothing in register \"" and the buffer is unchanged

### Requirement: Putting a blockwise register
"p" and "P" in normal mode with a blockwise register SHALL insert its rows count times as a block, starting on the cursor row at the display column after the cursor's character for "p" or at the cursor's for "P", padding rows that are too short with spaces and adding rows past the end of the buffer; the cursor goes to the block's first character.

#### Scenario: p puts a block after the cursor
- **WHEN** "<C-v>jly" is pressed at (0, 0) of ["abc", "def"], then "$p"
- **THEN** the lines are ["abcab", "defde"] and the cursor is at (0, 3)

#### Scenario: P pads a short row
- **WHEN** a block of the rows "x" and "y" is put with "P" at (0, 2) of ["abc", "d"]
- **THEN** the lines are ["abxc", "d y"]

#### Scenario: Rows past the end of the buffer
- **WHEN** a block of the rows "x" and "y" is put with "p" at (0, 0) of ["a"]
- **THEN** the lines are ["ax", " y"]

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

### Requirement: Comment operator
"gc" SHALL be a pending operator that toggles the comment of every whole line its motion or text object touches, and "gcc" SHALL toggle [count] lines from the cursor line. Counts SHALL multiply as for every operator. After a toggle the cursor SHALL be on the first non-blank of the first line, in normal mode. "gc" SHALL change no text but the comment markers.

#### Scenario: gcc comments the line
- **WHEN** "gcc" is pressed on row 0 of "a = 1" in a ruby buffer
- **THEN** the line is "# a = 1", the cursor is at (0, 0), and the mode is normal

#### Scenario: gc with a motion and a count
- **WHEN** "3gcj" is pressed on row 0 of ["a", "b", "c", "d", "e"]
- **THEN** the lines are ["# a", "# b", "# c", "# d", "e"]

#### Scenario: gcc with a count
- **WHEN** "2gcc" is pressed on row 1 of ["a", "b", "c", "d"]
- **THEN** the lines are ["a", "# b", "# c", "d"]

#### Scenario: gc with a text object
- **WHEN** "gcip" is pressed on row 0 of ["a", "b", "", "c"]
- **THEN** the lines are ["# a", "# b", "", "c"]

#### Scenario: gcc never deletes text
- **WHEN** "gcc8G" is pressed on row 2 of a buffer of ten lines
- **THEN** every line is kept, row 2 is commented, the cursor is on row 7, and the mode is normal

### Requirement: Comment toggle rule
When every non-blank line of the range is commented, a toggle SHALL uncomment each one, removing the marker and one space after it when there is one; a line left holding only blanks SHALL become empty. Otherwise a toggle SHALL comment every non-blank line, inserting the marker and one space at the smallest indent of the range's non-blank lines. A line is commented when its first non-blank characters are the marker. Blank lines SHALL be left untouched either way.

#### Scenario: Uncomment removes the marker and one space
- **WHEN** "gc2j" is pressed on row 0 of ["# a", "#b", "  #  c"]
- **THEN** the lines are ["a", "b", "   c"]

#### Scenario: A line of only the marker becomes empty
- **WHEN** "gcj" is pressed on row 0 of ["# a", "  #"]
- **THEN** the lines are ["a", ""]

#### Scenario: A mixed range is commented
- **WHEN** "gcj" is pressed on row 0 of ["# a", "b"]
- **THEN** the lines are ["# # a", "# b"]

#### Scenario: Blank lines are untouched
- **WHEN** "gc2j" is pressed on row 0 of ["a", "", "b"]
- **THEN** the lines are ["# a", "", "# b"], and uncommenting them again gives ["a", "", "b"]

#### Scenario: The marker goes at the smallest indent
- **WHEN** "gcj" is pressed on row 0 of ["    a", "  b"]
- **THEN** the lines are ["  #   a", "  # b"]

### Requirement: Comment marker by filetype
The comment marker SHALL come from the buffer's filetype through one table: "#" for ruby. A buffer whose filetype has no row in the table, or no filetype, SHALL use "#".

#### Scenario: An unknown filetype uses the default marker
- **WHEN** "gcc" is pressed on row 0 of "a" in a buffer named "a.txt"
- **THEN** the line is "# a"

### Requirement: Repeating and undoing a comment toggle
A whole toggle SHALL be one undo step, and "." SHALL repeat it on the lines at the cursor with the same count.

#### Scenario: One undo restores the toggled lines
- **WHEN** "3gcc" is pressed on row 0 of ["a", "b", "c"], then "u"
- **THEN** the lines are ["a", "b", "c"]

#### Scenario: Dot repeats the toggle
- **WHEN** "gcc" is pressed on row 0 of ["a", "b", "c"], then "j."
- **THEN** the lines are ["# a", "# b", "c"]

### Requirement: Comment operator in the visual modes
"gc" in visual, visual_line, and visual_block SHALL toggle the comment of every line the selection touches by the same rule, leave visual mode, and put the cursor on the first non-blank of the selection's first line.

#### Scenario: Visual gc
- **WHEN** "vjgc" is pressed on row 0 of ["a", "b", "c"]
- **THEN** the lines are ["# a", "# b", "c"] and the mode is normal

#### Scenario: Visual line gc uncomments
- **WHEN** "Vjgc" is pressed on row 0 of ["# a", "# b"]
- **THEN** the lines are ["a", "b"]

#### Scenario: Visual block gc toggles whole lines
- **WHEN** Ctrl-v, "j", "l", "gc" are pressed at (0, 1) of ["abc", "def"]
- **THEN** the lines are ["# abc", "# def"]
