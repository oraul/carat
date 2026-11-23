## ADDED Requirements

### Requirement: Format code points are shown as hexadecimal markers
A code point of a buffer line that reorders or hides text, U+061C, U+200B to U+200F, U+2028 to U+202E, U+2060 to U+206F, and U+FEFF, SHALL be displayed as "<" followed by four lowercase hexadecimal digits and ">", six cells wide, in the highlight of ordinary text, and no frame cell SHALL hold one raw. The frame cursor on such a code point SHALL be placed on the first cell of its marker, and the code point after it SHALL start six cells later.

#### Scenario: Override and zero-width marks as hexadecimal markers
- **WHEN** the lines "a‮b", "a​b", and "a﻿b" are each rendered with number off
- **THEN** the rows read "a<202e>b", "a<200b>b", and "a<feff>b", and no cell of the frame holds a format code point

#### Scenario: Cursor over and after a format marker
- **WHEN** the line "a​b" is rendered with number off and the cursor on the second code point, and then on the third
- **THEN** the frame cursor column is 1, and then 7
