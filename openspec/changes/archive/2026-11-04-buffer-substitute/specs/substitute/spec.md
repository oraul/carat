## Purpose

Substitute replaces matches of a search pattern with a replacement string over a range of lines, as Vim's `:s`, `:&`, `&`, and `g&` do, within bounds that keep untrusted patterns and replacements from crashing or hanging the editor.

## ADDED Requirements

### Requirement: :s replaces matches in a range of lines
`:[range]s[ubstitute]/{pattern}/{string}/[flags] [count]` SHALL replace, on each line of the range (the cursor line without one), the first match of the pattern with the string, or every match with the `g` flag. An empty pattern SHALL use the last search pattern. A trailing count SHALL run the command on count lines from the range's last line. An empty match next to the previous match SHALL not count, as in Vim.

#### Scenario: First match on the cursor line
- **WHEN** ":s/o/0/" is run on the line "foo"
- **THEN** the line is "f0o"

#### Scenario: Every match
- **WHEN** ":s/o/0/g" is run on the line "foo"
- **THEN** the line is "f00"

### Requirement: :s takes another delimiter
The delimiter SHALL be any ASCII character other than a letter, a digit, `\`, `"`, `|`, or a blank; a missing closing delimiter ends the string at the end of the line.

#### Scenario: Another delimiter
- **WHEN** ":s#/#-#g" is run on the line "a/b/c"
- **THEN** the line is "a-b-c"

#### Scenario: No closing delimiter
- **WHEN** ":s/b" is run on the line "abc"
- **THEN** the line is "ac"

#### Scenario: Empty pattern
- **WHEN** "/b" was searched and ":s//x/" is run on the line "abc"
- **THEN** the line is "axc"

#### Scenario: Empty matches
- **WHEN** ":s/x*/-/g" is run on the line "abc"
- **THEN** the line is "-a-b-c-"

#### Scenario: Count
- **WHEN** ":s/a/b/ 2" is run on the first of three lines holding "a"
- **THEN** lines 1 and 2 hold "b" and line 3 holds "a"

#### Scenario: A letter as delimiter
- **WHEN** ":sxaxbx" is run
- **THEN** the message is "E492: Not an editor command: sxaxbx"

### Requirement: The replacement string has Vim's special characters
In the string, `&` and `\0` SHALL insert the whole match, `\1` to `\9` the text of the pattern's `\(\)` groups (nothing for one that did not match), `~` the previous replacement string, `\u` and `\l` the next character in upper or lower case, `\U` and `\L` the following ones until `\e` or `\E`, `\r` a line break, `\t` a tab, and a backslash before any other character that character.

#### Scenario: The whole match
- **WHEN** ":s/b/[&]/" is run on "abc"
- **THEN** the line is "a[b]c"

#### Scenario: Groups
- **WHEN** ":s/\(a\)\(b\)/\2\1/" is run on "abc"
- **THEN** the line is "bac"

#### Scenario: Case
- **WHEN** ":s/\w\+/\u&/g" is run on "one two"
- **THEN** the line is "One Two"

#### Scenario: Line break
- **WHEN** ":s/,/\r/g" is run on "a,b,c"
- **THEN** the buffer holds the lines "a", "b", and "c"

#### Scenario: Previous replacement
- **WHEN** ":s/a/xy/" was run and ":s/b/~~/" is run on "b"
- **THEN** the line is "xyxy"

#### Scenario: Literal ampersand
- **WHEN** ":s/a/\&/" is run on "a"
- **THEN** the line is "&"

### Requirement: Unsupported replacement items are refused
`\=` at the start of the string and `\n` in it SHALL report Not implemented and change nothing. `~` in a substitute pattern SHALL match the previous replacement string.

#### Scenario: Expression
- **WHEN** ":s/a/\=1/" is run on "a"
- **THEN** the message is "Not implemented: \= in a substitute string" and the line is "a"

#### Scenario: Tilde in the pattern
- **WHEN** ":s/a/xy/" was run and ":s/~/z/" is run on "axy"
- **THEN** the line is "az"

### Requirement: Flags change how :s runs
The flags SHALL be read as in Vim: `&` first keeps the flags of the last substitute, otherwise they start from none; `g` toggles every match, `e` toggles reporting a pattern not found, `i` ignores case, `I` matches case, `n` counts the matches without changing the text, `r` makes a repeat use the last search pattern, `p` shows the last changed line, and `#` shows it with its number.

#### Scenario: Ignore case
- **WHEN** ":s/A/x/i" is run on "abc"
- **THEN** the line is "xbc"

#### Scenario: Count only
- **WHEN** ":%s/a//gn" is run on two lines "aa" and "a"
- **THEN** the message is "3 matches on 2 lines" and the text is unchanged

#### Scenario: No error
- **WHEN** ":s/z/y/e" is run on "abc"
- **THEN** no message is shown and the text is unchanged

### Requirement: Wrong flags are refused
`c` and `l` SHALL report Not implemented and change nothing. Any other text after the flags and count SHALL report "E488: Trailing characters: " with that text, and a count of 0 "E939: Positive count required".

#### Scenario: Trailing characters
- **WHEN** ":s/a/b/gx" is run
- **THEN** the message is "E488: Trailing characters: x"

#### Scenario: Confirm
- **WHEN** ":s/a/b/c" is run
- **THEN** the message is "Not implemented: :s flag c" and the text is unchanged

### Requirement: The last substitute can be repeated
`:[range]&[&][flags] [count]` and `:[range]s [flags] [count]` SHALL repeat the last substitute's pattern and string on the range, `&&` keeping its flags. `&` in normal mode SHALL repeat it on the cursor line without flags, on count lines with a count. `g&` SHALL repeat it on every line with its flags and the last search pattern.

#### Scenario: Repeat on another line
- **WHEN** ":s/a/b/" ran on line 1, the cursor moves to line 2 holding "a", and "&" is typed
- **THEN** line 2 holds "b"

#### Scenario: Repeat keeping flags
- **WHEN** ":s/a/b/g" ran and ":&&" is run on a line "aa"
- **THEN** the line is "bb"

#### Scenario: Repeat without flags
- **WHEN** ":s/a/b/g" ran and "&" is typed on a line "aa"
- **THEN** the line is "ba"

#### Scenario: Repeat everywhere
- **WHEN** ":s/a/b/g" ran on line 1 and "g&" is typed on a buffer whose other lines hold "aa"
- **THEN** every line holds "bb"

### Requirement: A repeat with nothing to repeat is refused
With no previous substitute `:&`, `:s` without a pattern, and `&` SHALL report "E33: No previous substitute regular expression", and `g&` with no previous search pattern "E35: No previous regular expression".

#### Scenario: Nothing to repeat
- **WHEN** "&" is typed before any substitute
- **THEN** the message is "E33: No previous substitute regular expression"

### Requirement: A substitute reports as Vim does
A substitute SHALL report "N substitutions on M lines" (singular forms for one) when it made more than two substitutions and nothing otherwise, and "E486: Pattern not found: " with the pattern when nothing matched, unless the `e` flag is given.

#### Scenario: Message for many substitutions
- **WHEN** ":%s/a/b/g" is run on two lines "aa" and "a"
- **THEN** the message is "3 substitutions on 2 lines"

#### Scenario: Not found
- **WHEN** ":s/z/y/" is run on "abc"
- **THEN** the message is "E486: Pattern not found: z"

### Requirement: A substitute is one undo step and sets the last search
A substitute SHALL be one undo step, SHALL not be repeated by ".", and SHALL leave the cursor on the first non-blank character of the last line it changed. Its pattern SHALL become the last search pattern that "n" repeats and highlights, the "/" register, and a search history entry.

#### Scenario: One undo step
- **WHEN** ":%s/a/b/" is run on three lines holding "a" and "u" is typed
- **THEN** every line holds "a" again

#### Scenario: n repeats the pattern
- **WHEN** ":s/b/x/" is run on "abc b" and "n" is typed
- **THEN** the cursor is on the "b" at column 4

### Requirement: Untrusted patterns and replacements are bounded
A substitute pattern SHALL be translated and capped as a search pattern is, and every scan of a line and every character of replacement text SHALL be charged to one work budget per command. When the budget runs out the command SHALL change nothing and report "E363: search stopped, pattern too costly here".

#### Scenario: A costly command stops
- **WHEN** a substitute would produce more replacement text than its budget allows
- **THEN** the message is "E363: search stopped, pattern too costly here" and the text is unchanged
