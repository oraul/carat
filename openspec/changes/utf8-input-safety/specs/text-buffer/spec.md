## ADDED Requirements

### Requirement: Bytes that are not UTF-8 are kept
A buffer loaded from text that is not valid UTF-8 SHALL hold every byte of it in its lines, split only at its newlines, and SHALL produce the same file text again when nothing was edited. Yanking, deleting, and putting text that holds such bytes SHALL keep them, and the case operators SHALL change only ASCII letters in text that is not valid UTF-8.

#### Scenario: Hostile bytes load and round-trip
- **WHEN** a buffer is loaded from each of "caf\xE9\n", "a\xC0\xAFb\n", "\xED\xA0\x80\n", "\xF4\x90\x80\x80\n", "\xE4\xB8\n", "\x80\n", and "a\x00b\n"
- **THEN** each has one line equal to its text without the newline, and its file text equals the text it was loaded from

#### Scenario: Windows endings with an illegal byte
- **WHEN** a buffer is loaded from "\xFFa\r\nb\r\n"
- **THEN** the lines are ["\xFFa", "b"], the line ending is "\r\n", and the file text is "\xFFa\r\nb\r\n"

#### Scenario: Yank and put a line with an illegal byte
- **WHEN** the buffer holds "a\xFFb" and "yyp" is pressed
- **THEN** the lines are ["a\xFFb", "a\xFFb"]

#### Scenario: Case change leaves illegal bytes alone
- **WHEN** the buffer holds "a\xC0\xAFb" and "VU" is pressed, or "~~~~" from the first column
- **THEN** the line is "A\xC0\xAFB"
