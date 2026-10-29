# Spec Delta

## ADDED Requirements

### Requirement: Unprintable code points are shown as escape markers
A code point below 32 in a buffer line SHALL be displayed as a caret and the letter 64 above it, two cells wide. U+007F and the code points U+0080 to U+009F SHALL be displayed as "<" followed by two lowercase hexadecimal digits and ">", four cells wide. Both markers SHALL use the highlight of ordinary text, and the frame cursor on such a code point SHALL be placed on the first cell of its marker.

#### Scenario: Caret notation for a C0 control
- **WHEN** the line "a\x01b" is rendered with number off
- **THEN** the row reads "a^Ab"

#### Scenario: Delete and C1 controls as hexadecimal markers
- **WHEN** the lines "a\u007Fb", "a\u0080b", "a\u009Bb", and "a\u009Db" are each rendered with number off
- **THEN** the rows read "a<7f>b", "a<80>b", "a<9b>b", and "a<9d>b", and the cell after each marker is at column 5

#### Scenario: Cursor over and after a marker
- **WHEN** the line "a\u009Bb" is rendered with number off and the cursor on the second code point, and then on the third
- **THEN** the frame cursor column is 1, and then 5

### Requirement: No control code point reaches a frame cell or the terminal
No cell of a frame SHALL hold a code point below 32, U+007F, or U+0080 to U+009F. Text written to the frame that contains such a code point SHALL store U+FFFD in its cell instead. The bytes written to the terminal for a frame SHALL contain no C0 or C1 code point other than the escape sequences the screen presenter writes itself.

#### Scenario: A rendered line leaves no control code point in the frame
- **WHEN** a line containing U+007F, U+0080, U+009B, and U+009D is rendered
- **THEN** every cell of the frame holds a code point that is 32 or above, not U+007F, and outside U+0080 to U+009F

#### Scenario: Text written to the frame directly
- **WHEN** the text "a\u009Bb" is written to a frame row
- **THEN** the row's cells hold "a", U+FFFD, and "b"

#### Scenario: Terminal bytes for a frame with markers
- **WHEN** a frame drawn from a line containing U+009B and U+009D is presented
- **THEN** the bytes written contain the markers "<9b>" and "<9d>" and, outside the presenter's own escape sequences, no byte sequence encoding a code point from U+0080 to U+009F
