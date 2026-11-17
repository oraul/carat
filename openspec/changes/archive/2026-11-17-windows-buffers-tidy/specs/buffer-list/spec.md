## ADDED Requirements

### Requirement: Control characters in a buffer's name

A control character in a buffer's name (a C0 control or DEL) SHALL be shown in caret notation, `^` and the character 64 above it (`^J` for a newline, `^?` for DEL), in the `:ls` listing and in the E162 refusal of quitting, so no name breaks either message into lines.

#### Scenario: A newline in a name in the listing

- **WHEN** the editor is on a file whose name is "x" followed by a newline and "y.txt" and ":ls" is run
- **THEN** the message is one line naming "x^Jy.txt"

#### Scenario: A newline in a name in E162

- **WHEN** that buffer is modified and ":qa" is run
- **THEN** the editor stays and the message is "E37: No write since last change" and "E162: No write since last change for buffer "x^Jy.txt"" on two lines
